import SwiftUI
import TrailMarkCore

struct RecordAudioView: View {
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    
    @State private var recorder = AudioRecorder()
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 32) {
                Spacer()
                
                Text(timeString(recorder.elapsedTime))
                    .font(.system(size: 56, design: .rounded).monospacedDigit())
                    .contentTransition(.numericText())
                
                Image(systemName: recorder.isRecording ? "waveform.circle.fill" : "mic.circle")
                    .font(.system(size: 96))
                    .foregroundStyle(recorder.isRecording ? .red : .secondary)
                    .symbolEffect(.pulse, isActive: recorder.isRecording)
                
                Spacer()
                
                Button {
                    recorder.isRecording ? finish() : begin()
                } label: {
                    Text(recorder.isRecording  ? "Stop and Save" : "Start Recording")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(recorder.isRecording ? Color.red : Color.accentColor, in: RoundedRectangle(cornerRadius: 14))
                        .foregroundStyle(.white)
                }
                
                if let errorMessage {
                    Text(errorMessage).font(.footnote).foregroundStyle(.red)
                }
            }
            .padding()
            .navigationTitle("Voice Memo")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .task(id: recorder.isRecording) {
                while recorder.isRecording && !Task.isCancelled {
                    recorder.tick()
                    try? await Task.sleep(for: .seconds(0.3))
                }
            }
        }
    }
    
    private func timeString(_ interval: TimeInterval) -> String {
        let minutes = Int(interval) / 60
        let seconds = Int(interval) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    private func begin() {
        do { try recorder.startRecording() }
        catch { errorMessage = error.localizedDescription }
    }
    
    private func finish() {
        guard let result = recorder.stop() else { return }
        _ = try? model.media.add(kind: .audio, movingFileFrom: result.url, duration: result.duration)
        dismiss()
    }
}

#Preview {
    RecordAudioView()
        .environment(AppModel())
}
