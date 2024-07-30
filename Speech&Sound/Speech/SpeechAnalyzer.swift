//
//  SpeechAnalyzer.swift
//  Speech&Sound
//
//  Created by William Handoko on 30/07/24.
//

import Foundation
import Speech
import SwiftUI

class SpeechAnalyzer: NSObject, ObservableObject, SFSpeechRecognizerDelegate {
    private let audioEngine = AVAudioEngine()
    private var inputNode: AVAudioInputNode?
    private var speechRecognizer: SFSpeechRecognizer?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private var audioSession: AVAudioSession?
    
    @Published var recognizedText: String?
    @Published var isProcessing: Bool = false
    
    private var silenceTimer: Timer?
    private let silenceTimeout: TimeInterval = 3.0 // 3 seconds of silence

    func start() {
        audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession?.setCategory(.record, mode: .measurement, options: .duckOthers)
            try audioSession?.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            print("Couldn't configure the audio session")
        }
        
        inputNode = audioEngine.inputNode
        speechRecognizer = SFSpeechRecognizer()
        print("Supports on device recognition: \(speechRecognizer?.supportsOnDeviceRecognition == true ? "🔴" : "✅")")
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let speechRecognizer = speechRecognizer, speechRecognizer.isAvailable, let recognitionRequest = recognitionRequest, let inputNode = inputNode else {
            assertionFailure("Unable to start")
            return
        }
        
        speechRecognizer.delegate = self
        
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) {
            (buffer: AVAudioPCMBuffer, when: AVAudioTime) in recognitionRequest.append(buffer)
        }
        
        recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            self?.recognizedText = result?.bestTranscription.formattedString
            
            // Reset the silence timer whenever new speech is recognized
            self?.resetSilenceTimer()
            
            guard error != nil || result?.isFinal == true else { return }
            self?.stop()
        }
        
        audioEngine.prepare()
        
        do {
            try audioEngine.start()
            isProcessing = true
            resetSilenceTimer()
        } catch {
            print("Couldn't start audio engine")
            stop()
        }
    }
    
    func stop() {
        recognitionTask?.cancel()
        
        audioEngine.stop()
        
        inputNode?.removeTap(onBus: 0)
        try? audioSession?.setActive(false)
        audioSession = nil
        inputNode = nil
        
        isProcessing = false
        
        recognitionRequest = nil
        recognitionTask = nil
        speechRecognizer = nil
        
        silenceTimer?.invalidate()
        silenceTimer = nil
    }
    
    private func resetSilenceTimer() {
        silenceTimer?.invalidate()
        silenceTimer = Timer.scheduledTimer(withTimeInterval: silenceTimeout, repeats: false) { [weak self] _ in
            self?.stop()
        }
    }
    
    func speechRecognizer(_ speechRecognizer: SFSpeechRecognizer, availabilityDidChange available: Bool) {
        if available {
            print("Active")
        } else {
            print("Inactive")
            recognizedText = "Unavailable"
            stop()
        }
    }
}
