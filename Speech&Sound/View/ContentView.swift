//
//  ContentView.swift
//  Speech&Sound
//
//  Created by William Handoko on 30/07/24.
//

import SwiftUI

struct ContentView: View {
    private enum Constans {
        static let recognizeButtonSide: CGFloat = 100
    }

    @State private var score: Int = 0
    @State private var randomInt = Int.random(in: 0..<100)
    @ObservedObject private var speechAnalyzer = SpeechAnalyzer()
    
    var body: some View {
        VStack {
            Text("Score \(score)")
            
            Text("\(randomInt)")
                .foregroundStyle(speechAnalyzer.recognizedText == String(randomInt) ? Color.green : Color.red)
            
            Spacer()
            
            Text(speechAnalyzer.recognizedText ?? "Tap to begin")
                .padding()
            
            Button {
                toggleSpeechRecognition()
            } label: {
                Image(systemName: speechAnalyzer.isProcessing ? "waveform.circle.fill" : "waveform.circle")
                    .resizable()
                    .frame(width: Constans.recognizeButtonSide,
                           height: Constans.recognizeButtonSide,
                           alignment: .center)
                    .foregroundColor(speechAnalyzer.isProcessing ? .red : .gray)
                    .aspectRatio(contentMode: .fit)
            }
            .padding()
        }
        
        .onChange(of: speechAnalyzer.recognizedText) {
            checkRecognition(newText: speechAnalyzer.recognizedText)
        }
    }
    
    func checkRecognition(newText: String?) {
        if newText == String(randomInt) {
            addScore()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                randomInt = Int.random(in: 0..<100)
                speechAnalyzer.stop()
            }
        }
    }
    
    func addScore() {
        score += 1
    }
}

#Preview {
    ContentView()
}

private extension ContentView {
    func toggleSpeechRecognition() {
        if speechAnalyzer.isProcessing {
            speechAnalyzer.stop()
        } else {
            speechAnalyzer.start()
        }
    }
}
