use ndarray::{Array3, Array4};
use ort::{
    session::{
        builder::{GraphOptimizationLevel, SessionBuilder},
        Session,
    },
    value::TensorRef,
};
use realfft::{num_complex::Complex, ComplexToReal, RealFftPlanner, RealToComplex};
use std::ffi::c_void;
use std::sync::Arc;

const MODEL_1: &[u8] = include_bytes!("../models/model_128_1.onnx");
const MODEL_2: &[u8] = include_bytes!("../models/model_128_2.onnx");
const STATE_SIZE: usize = 128;
const BLOCK_SIZE: usize = 512;
const BLOCK_SHIFT: usize = 128;

struct CircularBuffer {
    buffer: Vec<f32>,
    block_len: usize,
    block_shift: usize,
}

impl CircularBuffer {
    fn new(block_len: usize, block_shift: usize) -> Self {
        Self {
            buffer: vec![0.0; block_len],
            block_len,
            block_shift,
        }
    }

    fn push_chunk(&mut self, chunk: &[f32]) {
        let keep = self.block_len - self.block_shift;
        self.buffer.copy_within(self.block_shift.., 0);
        let copy_len = chunk.len().min(self.block_shift);
        self.buffer[keep..keep + copy_len].copy_from_slice(&chunk[..copy_len]);

        if copy_len < self.block_shift {
            self.buffer[keep + copy_len..].fill(0.0);
        }
    }

    fn shift_and_accumulate(&mut self, data: &[f32]) {
        let keep = self.block_len - self.block_shift;
        self.buffer.copy_within(self.block_shift.., 0);
        self.buffer[keep..].fill(0.0);

        for (target, &value) in self.buffer.iter_mut().zip(data.iter()) {
            *target += value;
        }
    }

    fn data(&self) -> &[f32] {
        &self.buffer
    }

    fn clear(&mut self) {
        self.buffer.fill(0.0);
    }
}

struct ProcessingContext {
    scratch: Vec<Complex<f32>>,
    ifft_scratch: Vec<Complex<f32>>,
    in_buffer_fft: Vec<f32>,
    in_block_fft: Vec<Complex<f32>>,
    lpb_buffer_fft: Vec<f32>,
    lpb_block_fft: Vec<Complex<f32>>,
    estimated_block_vec: Vec<f32>,
    in_mag: Array3<f32>,
    lpb_mag: Array3<f32>,
    estimated_block: Array3<f32>,
    in_lpb: Array3<f32>,
    out_mask: Vec<f32>,
    out_block: Vec<f32>,
}

impl ProcessingContext {
    fn new(
        block_len: usize,
        fft: &Arc<dyn RealToComplex<f32>>,
        ifft: &Arc<dyn ComplexToReal<f32>>,
    ) -> Self {
        Self {
            scratch: vec![Complex::new(0.0, 0.0); fft.get_scratch_len()],
            ifft_scratch: vec![Complex::new(0.0, 0.0); ifft.get_scratch_len()],
            in_buffer_fft: vec![0.0; block_len],
            in_block_fft: vec![Complex::new(0.0, 0.0); block_len / 2 + 1],
            lpb_buffer_fft: vec![0.0; block_len],
            lpb_block_fft: vec![Complex::new(0.0, 0.0); block_len / 2 + 1],
            estimated_block_vec: vec![0.0; block_len],
            in_mag: Array3::zeros((1, 1, block_len / 2 + 1)),
            lpb_mag: Array3::zeros((1, 1, block_len / 2 + 1)),
            estimated_block: Array3::zeros((1, 1, block_len)),
            in_lpb: Array3::zeros((1, 1, block_len)),
            out_mask: vec![0.0; block_len / 2 + 1],
            out_block: vec![0.0; block_len],
        }
    }
}

struct NeuralAec {
    session_1: Session,
    session_2: Session,
    fft: Arc<dyn RealToComplex<f32>>,
    ifft: Arc<dyn ComplexToReal<f32>>,
    states_1: Array4<f32>,
    states_2: Array4<f32>,
    in_buffer: CircularBuffer,
    in_buffer_lpb: CircularBuffer,
    out_buffer: CircularBuffer,
}

impl NeuralAec {
    fn new() -> Result<Self, String> {
        let mut fft_planner = RealFftPlanner::<f32>::new();
        let fft = fft_planner.plan_fft_forward(BLOCK_SIZE);
        let ifft = fft_planner.plan_fft_inverse(BLOCK_SIZE);

        Ok(Self {
            session_1: load_model(MODEL_1)?,
            session_2: load_model(MODEL_2)?,
            fft,
            ifft,
            states_1: Array4::zeros((1, 2, STATE_SIZE, 2)),
            states_2: Array4::zeros((1, 2, STATE_SIZE, 2)),
            in_buffer: CircularBuffer::new(BLOCK_SIZE, BLOCK_SHIFT),
            in_buffer_lpb: CircularBuffer::new(BLOCK_SIZE, BLOCK_SHIFT),
            out_buffer: CircularBuffer::new(BLOCK_SIZE, BLOCK_SHIFT),
        })
    }

    fn reset(&mut self) {
        self.states_1.fill(0.0);
        self.states_2.fill(0.0);
        self.in_buffer.clear();
        self.in_buffer_lpb.clear();
        self.out_buffer.clear();
    }

    fn process_streaming(&mut self, mic: &[f32], speaker: &[f32]) -> Result<Vec<f32>, String> {
        let len = mic.len().min(speaker.len());
        if len == 0 {
            return Ok(Vec::new());
        }

        let mic = &mic[..len];
        let speaker = &speaker[..len];
        let mut output = vec![0.0; len];
        let mut ctx = ProcessingContext::new(BLOCK_SIZE, &self.fft, &self.ifft);
        let blocks = len / BLOCK_SHIFT;

        for block in 0..blocks {
            let start = block * BLOCK_SHIFT;
            let end = start + BLOCK_SHIFT;

            self.in_buffer.push_chunk(&mic[start..end]);
            self.in_buffer_lpb.push_chunk(&speaker[start..end]);

            calculate_fft_magnitude(
                &self.fft,
                self.in_buffer.data(),
                &mut ctx.in_buffer_fft,
                &mut ctx.in_block_fft,
                &mut ctx.scratch,
                &mut ctx.in_mag,
            )?;

            calculate_fft_magnitude(
                &self.fft,
                self.in_buffer_lpb.data(),
                &mut ctx.lpb_buffer_fft,
                &mut ctx.lpb_block_fft,
                &mut ctx.scratch,
                &mut ctx.lpb_mag,
            )?;

            self.run_model_1(&mut ctx)?;

            for (complex, &mask) in ctx.in_block_fft.iter_mut().zip(ctx.out_mask.iter()) {
                *complex *= mask;
            }

            self.ifft
                .process_with_scratch(
                    &mut ctx.in_block_fft,
                    &mut ctx.estimated_block_vec,
                    &mut ctx.ifft_scratch,
                )
                .map_err(|error| error.to_string())?;

            let norm = 1.0 / BLOCK_SIZE as f32;
            for (target, &sample) in ctx
                .estimated_block
                .as_slice_mut()
                .ok_or("estimated block is not contiguous")?
                .iter_mut()
                .zip(ctx.estimated_block_vec.iter())
            {
                *target = sample * norm;
            }

            ctx.in_lpb
                .as_slice_mut()
                .ok_or("lpb block is not contiguous")?
                .copy_from_slice(self.in_buffer_lpb.data());

            self.run_model_2(&mut ctx)?;
            self.out_buffer.shift_and_accumulate(&ctx.out_block);
            output[start..end].copy_from_slice(&self.out_buffer.data()[..BLOCK_SHIFT]);
        }

        normalize_output(&mut output);
        Ok(output)
    }

    fn run_model_1(&mut self, ctx: &mut ProcessingContext) -> Result<(), String> {
        let mut outputs = self
            .session_1
            .run(ort::inputs![
                TensorRef::from_array_view(ctx.in_mag.view()).map_err(|error| error.to_string())?,
                TensorRef::from_array_view(self.states_1.view()).map_err(|error| error.to_string())?,
                TensorRef::from_array_view(ctx.lpb_mag.view()).map_err(|error| error.to_string())?,
            ])
            .map_err(|error| error.to_string())?;

        let out_mask = outputs
            .remove("Identity")
            .ok_or("model_1 missing Identity output")?;
        let out_mask_view = out_mask
            .try_extract_array::<f32>()
            .map_err(|error| error.to_string())?;
        ctx.out_mask.copy_from_slice(
            out_mask_view
                .view()
                .as_slice()
                .ok_or("model_1 mask output is not contiguous")?,
        );

        let new_states = outputs
            .remove("Identity_1")
            .ok_or("model_1 missing Identity_1 output")?;
        let new_states_view = new_states
            .try_extract_array::<f32>()
            .map_err(|error| error.to_string())?;
        self.states_1
            .as_slice_mut()
            .ok_or("model_1 state buffer is not contiguous")?
            .copy_from_slice(
                new_states_view
                    .view()
                    .as_slice()
                    .ok_or("model_1 state output is not contiguous")?,
            );

        Ok(())
    }

    fn run_model_2(&mut self, ctx: &mut ProcessingContext) -> Result<(), String> {
        let mut outputs = self
            .session_2
            .run(ort::inputs![
                TensorRef::from_array_view(ctx.estimated_block.view()).map_err(|error| error.to_string())?,
                TensorRef::from_array_view(self.states_2.view()).map_err(|error| error.to_string())?,
                TensorRef::from_array_view(ctx.in_lpb.view()).map_err(|error| error.to_string())?,
            ])
            .map_err(|error| error.to_string())?;

        let out_block = outputs
            .remove("Identity")
            .ok_or("model_2 missing Identity output")?;
        let out_block_view = out_block
            .try_extract_array::<f32>()
            .map_err(|error| error.to_string())?;
        ctx.out_block.copy_from_slice(
            out_block_view
                .view()
                .as_slice()
                .ok_or("model_2 audio output is not contiguous")?,
        );

        let new_states = outputs
            .remove("Identity_1")
            .ok_or("model_2 missing Identity_1 output")?;
        let new_states_view = new_states
            .try_extract_array::<f32>()
            .map_err(|error| error.to_string())?;
        self.states_2
            .as_slice_mut()
            .ok_or("model_2 state buffer is not contiguous")?
            .copy_from_slice(
                new_states_view
                    .view()
                    .as_slice()
                    .ok_or("model_2 state output is not contiguous")?,
            );

        Ok(())
    }
}

fn load_model(bytes: &[u8]) -> Result<Session, String> {
    session_builder()
        .and_then(|builder| builder.commit_from_memory(bytes).map_err(|error| error.to_string()))
}

fn session_builder() -> Result<SessionBuilder, String> {
    Session::builder()
        .and_then(|builder| builder.with_intra_threads(1))
        .and_then(|builder| builder.with_inter_threads(1))
        .and_then(|builder| builder.with_optimization_level(GraphOptimizationLevel::Level3))
        .map_err(|error| error.to_string())
}

fn calculate_fft_magnitude(
    fft: &Arc<dyn RealToComplex<f32>>,
    input: &[f32],
    fft_buffer: &mut [f32],
    fft_result: &mut [Complex<f32>],
    scratch: &mut [Complex<f32>],
    magnitude: &mut Array3<f32>,
) -> Result<(), String> {
    fft_buffer.copy_from_slice(input);
    fft.process_with_scratch(fft_buffer, fft_result, scratch)
        .map_err(|error| error.to_string())?;

    for (index, value) in fft_result.iter().enumerate() {
        magnitude[[0, 0, index]] = value.norm();
    }

    Ok(())
}

fn normalize_output(output: &mut [f32]) {
    let max = output.iter().fold(0.0f32, |acc, &value| acc.max(value.abs()));
    if max > 1.0 {
        let scale = 0.99 / max;
        output.iter_mut().for_each(|sample| *sample *= scale);
    }
}

#[repr(C)]
pub struct FlowvoiceAec {
    inner: NeuralAec,
}

#[unsafe(no_mangle)]
pub extern "C" fn flowvoice_aec_create() -> *mut FlowvoiceAec {
    match NeuralAec::new() {
        Ok(inner) => Box::into_raw(Box::new(FlowvoiceAec { inner })),
        Err(error) => {
            eprintln!("flowvoice_aec_create failed: {error}");
            std::ptr::null_mut()
        }
    }
}

#[unsafe(no_mangle)]
pub unsafe extern "C" fn flowvoice_aec_destroy(handle: *mut FlowvoiceAec) {
    if !handle.is_null() {
        unsafe { drop(Box::from_raw(handle)); }
    }
}

#[unsafe(no_mangle)]
pub unsafe extern "C" fn flowvoice_aec_reset(handle: *mut FlowvoiceAec) {
    if let Some(aec) = unsafe { handle.as_mut() } {
        aec.inner.reset();
    }
}

#[unsafe(no_mangle)]
pub unsafe extern "C" fn flowvoice_aec_process(
    handle: *mut FlowvoiceAec,
    microphone: *const i16,
    speaker: *const i16,
    output: *mut i16,
    sample_count: usize,
) -> usize {
    let Some(aec) = (unsafe { handle.as_mut() }) else {
        return 0;
    };

    if microphone.is_null() || speaker.is_null() || output.is_null() || sample_count == 0 {
        return 0;
    }

    let mic = unsafe { std::slice::from_raw_parts(microphone, sample_count) };
    let speaker = unsafe { std::slice::from_raw_parts(speaker, sample_count) };
    let output = unsafe { std::slice::from_raw_parts_mut(output, sample_count) };

    let mic_f32: Vec<f32> = mic.iter().map(|&sample| sample as f32 / 32768.0).collect();
    let speaker_f32: Vec<f32> = speaker.iter().map(|&sample| sample as f32 / 32768.0).collect();

    let processed = match aec.inner.process_streaming(&mic_f32, &speaker_f32) {
        Ok(processed) => processed,
        Err(error) => {
            eprintln!("flowvoice_aec_process failed: {error}");
            return 0;
        }
    };

    let written = processed.len().min(output.len());
    for (target, &sample) in output.iter_mut().zip(processed.iter()).take(written) {
        let scaled = (sample.clamp(-1.0, 1.0) * 32767.0).round();
        *target = scaled.clamp(i16::MIN as f32, i16::MAX as f32) as i16;
    }

    written
}

#[unsafe(no_mangle)]
pub extern "C" fn flowvoice_aec_block_shift() -> usize {
    BLOCK_SHIFT
}

#[unsafe(no_mangle)]
pub extern "C" fn flowvoice_aec_abi_token() -> *const c_void {
    flowvoice_aec_create as *const c_void
}


#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn processes_streaming_silence() {
        let mut aec = NeuralAec::new().expect("AEC model should load");
        let microphone = vec![0.0f32; BLOCK_SHIFT * 12];
        let speaker = vec![0.0f32; BLOCK_SHIFT * 12];
        let output = aec
            .process_streaming(&microphone, &speaker)
            .expect("silence should process");

        assert_eq!(output.len(), microphone.len());
        assert!(output.iter().all(|sample| sample.is_finite()));
    }
}
