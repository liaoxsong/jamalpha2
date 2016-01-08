//
//  PlaySoundManager.swift
//  aaa
//
//  Created by Jun Zhou on 1/5/16.
//  Copyright © 2016 myStride. All rights reserved.
//

import Foundation
import QuartzCore

class PlayChordsManager: NSObject {
    var soundBank: SoundBankPlayer!
    var timer: NSTimer!
    var playingArpeggio: Bool = false
    var arpeggioStartTime: CFTimeInterval = 0
    var arpeggioDelay: CFTimeInterval = 0
    var arpeggioNotes: NSArray = NSArray()
    var arpeggioIndex: Int = 0
    
    class var sharedInstance: PlayChordsManager {
        struct Static {
            static var onceToken: dispatch_once_t = 0
            static var instance: PlayChordsManager? = nil
        }
        dispatch_once(&Static.onceToken) {
            Static.instance = PlayChordsManager()
        }
        return Static.instance!
    }
    
    override init() {
        super.init()
        initialSoundBank()
    }
    
    func convertIndexToMidi(index: Int) -> Int32 {
        let fret0Midi = [52, 57, 62, 67, 71, 76]
        let stringIndex = index / 100
        let fretIndex = index - stringIndex * 100
        return Int32(fret0Midi[stringIndex] + fretIndex)
    }
    
    func convertContentToIndexArray(content: String) -> [Int32] {
        var midiArray: [Int32] = [Int32]()
        for var i = 11; i >= 0; i = i - 2 {
            let startIndex = content.startIndex.advancedBy(11 - i)
            let endIndex = content.startIndex.advancedBy(11 - i + 2)
            let charAtIndex = content[Range(start: startIndex, end: endIndex)]
            var indexFret: Int = Int()
            if charAtIndex == "xx" {
                indexFret = 0
            } else {
                indexFret = Int(String(charAtIndex))!
                let indexString = i / 2 + 1
                let index = indexString * 100 + indexFret
                midiArray.append(convertIndexToMidi(index))
            }
        }
        return midiArray.reverse()
    }
    
    func initialSoundBank() {
        self.soundBank = SoundBankPlayer()
        self.soundBank.setSoundBank("GuitarSoundFont")
        self.playingArpeggio = false
    }
    
    func deinitialSoundBank() {
        self.stopTimer()
    }
    
    func playSingleNoteSound(index: Int) {
        let midi = convertIndexToMidi(index)
        soundBank.queueNote(midi, gain: 0.4)
        soundBank.playQueuedNotes()
    }
    
    func playChordSimultenous(content: String) {
        let midiArray: [Int32] = convertContentToIndexArray(content)
        for item in midiArray {
            soundBank.queueNote(item, gain: 0.4)
        }
        soundBank.playQueuedNotes()
    }
    
    func playChordArpeggio(content: String, delay: CFTimeInterval, completion: ((complete: Bool) -> Void)) {
        self.startTimer()
        let midiArray: [Int32] = convertContentToIndexArray(content)
        if playingArpeggio == false {
            playingArpeggio = true
            arpeggioNotes = [NSNumber(int:midiArray[0]), NSNumber(int:midiArray[1]), NSNumber(int:midiArray[2]), NSNumber(int:midiArray[3]), NSNumber(int:midiArray[4]), NSNumber(int:midiArray[5])]
            arpeggioIndex = 0
            arpeggioDelay = delay
            arpeggioStartTime = CACurrentMediaTime()
        }
    }
    
    func startTimer() {
        self.timer = NSTimer.scheduledTimerWithTimeInterval(0.05, target: self, selector: "handleTimer:", userInfo: nil, repeats: true)
    }
    
    func stopTimer() {
        self.timer.invalidate()
        self.timer = nil
    }
    
    func handleTimer(timer: NSTimer) {
        if playingArpeggio {
            let now: CFTimeInterval = CACurrentMediaTime()
            if now - arpeggioStartTime >= arpeggioDelay {
                let number: NSNumber = arpeggioNotes[arpeggioIndex] as! NSNumber
                soundBank.noteOn(number.intValue, gain: 0.4)
                arpeggioIndex = arpeggioIndex + 1
                if arpeggioIndex == arpeggioNotes.count {
                    playingArpeggio = false
                    arpeggioNotes = NSArray()
                } else {
                    arpeggioStartTime = now
                }
            }
        }
    }
}