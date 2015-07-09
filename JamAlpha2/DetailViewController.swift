

import UIKit
import MediaPlayer
import AVFoundation

class DetailViewController: UIViewController {
    
    // MARK: for testing in simulator
    var audioPlayer = AVAudioPlayer()
    var isTesting = false
    
    var theSong:MPMediaItem!
    
    //@IBOutlet weak var base: ChordBase!
    @IBOutlet weak var playPauseButton: UIButton!
    @IBOutlet weak var progressBar: UISlider!
    
    // MARK : Custom views
    var base : ChordBase!
    var progressView : UIView!
    
    var isPause: Bool = true
    let player = MPMusicPlayerController.applicationMusicPlayer()
    var chords = [Chord]()
    var start: Int = 0
    var activelabels = [[UILabel]]()
    var startTime: Float = 0
    var timer: NSTimer = NSTimer()
    
    var topPoints = [CGFloat]()
    var bottomPoints = [CGFloat]()
    
    var labelHeight:CGSize!
    //speed to control playback speed and
    //corresponding playback speed
    var speed = 1
    
    var rangeOfChords:Float = 5
    
    //Lyric
    var lyricbase: UIView = UIView()
    
    var label1: UILabel = UILabel()
    var label2: UILabel = UILabel()
    
    var current: Int = 0    //current line of lyric
    var lyric: Lyric = Lyric()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationController?.navigationBar.barTintColor = UIColor.whiteColor()
        
        self.tabBarController?.tabBar.hidden = true
        base = ChordBase(frame: CGRect(x: 0, y: 100, width: self.view.frame.width * 0.7, height: self.view.frame.height * 0.4))
        base.center.x = self.view.center.x
        base.backgroundColor = UIColor.whiteColor()
        self.view.addSubview(base)
        
        
        
        calculateXPoints()
        setUpDemoChords()
        progressBar.minimumValue = 0
        var progressViewWidth:CGFloat
        if isTesting {
            
            setUpTestSong()
    
            progressBar.maximumValue = Float(audioPlayer.duration)
     
            println("duration \(audioPlayer.duration)")
            progressViewWidth = CGFloat(audioPlayer.duration) * 8
           
            
        } else {
            setUpSong()
           
            progressBar.minimumValue = 0
            progressBar.maximumValue = Float(theSong.playbackDuration)
            progressBar.value = 0
            progressViewWidth = CGFloat(theSong.playbackDuration) * 8


        }
        
        progressView = UIView(frame: CGRect(x: self.view.frame.width / 2, y: self.playPauseButton.frame.origin.y - 50, width: progressViewWidth, height: 10))
        progressBar.value = 0
        progressView.backgroundColor = mainPinkColor
        self.view.addSubview(progressView)
        
        //Lyric labels
        current = -1
        lyricbase.frame = CGRectMake(base.frame.origin.x, base.frame.origin.y + base.frame.height, base.frame.width, base.frame.height / 3)
        lyricbase.backgroundColor = mainPinkColor
        self.view.addSubview(lyricbase)
        
        label1.frame = CGRectMake(0, 0, lyricbase.frame.width, 2 * lyricbase.frame.height/3)
        label1.center = CGPointMake(lyricbase.frame.width/2, lyricbase.frame.height/3)
        label1.numberOfLines = 2
        label1.textAlignment = NSTextAlignment.Center
        label1.font = UIFont.systemFontOfSize(15)
        label1.lineBreakMode = .ByWordWrapping
        lyricbase.addSubview(label1)
        
        label2.frame = CGRectMake(0, 0, lyricbase.frame.width, lyricbase.frame.height / 3)
        label2.center = CGPointMake(lyricbase.frame.width/2, 5 * lyricbase.frame.height/6)
        label2.numberOfLines = 2
        label2.textAlignment = NSTextAlignment.Center
        label2.font = UIFont.systemFontOfSize(10)
        label2.lineBreakMode = .ByWordWrapping
        lyricbase.addSubview(label2)
        
        updateAll(0)
    }
    
    func setUpTestSong(){

            if var filePath = NSBundle.mainBundle().pathForResource("彩虹",ofType:"mp3"){
                
                var fileWithPath = NSURL.fileURLWithPath(filePath)
                audioPlayer = AVAudioPlayer(contentsOfURL: fileWithPath, error: nil)
            }
            else{
                println("mp3 not found")
            }
        
        
        audioPlayer.prepareToPlay()
    }
    override func prefersStatusBarHidden() -> Bool {
        return true
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        self.tabBarController?.tabBar.hidden = false
        if isTesting {
            audioPlayer.stop()
        }
    }
    
    func calculateXPoints(){
        let width = base.frame.width
        
        let margin:Float = 0.25
        let initialPoint:CGFloat = CGFloat(Float(width) * margin)
        let rightTopPoint:CGFloat = CGFloat(Float(width) * (1 - margin))
        
        let scale:Float = 1 / 12
        let topWidth = Float(rightTopPoint) - Float(initialPoint)
        let topLeft = Float(initialPoint) + Float(topWidth) * scale
        topPoints = [CGFloat](count: 6, repeatedValue: 0)
        
        topPoints[0] = CGFloat(topLeft)
        for i in 1..<6 {
            topPoints[i] = CGFloat(Float(topPoints[i - 1]) + Float(topWidth * scale * 2))
        }
        
        bottomPoints = [CGFloat](count: 6, repeatedValue: 0)
        bottomPoints[0] = CGFloat(Float(width) * scale)
        for i in 1..<6 {
            bottomPoints[i] = CGFloat(Float(bottomPoints[i - 1]) + Float(width) * scale * 2)
        }
    }
    
    func setUpDemoChords(){
        var CMajor = Tab(name:"C",content:"032010")
        var DMajor = Tab(name:"D",content:"000232")
        var EMinor = Tab(name:"Em",content:"022000")
        var FMajor = Tab(name:"F",content:"133210")
        
        var chord1 = Chord(tab: CMajor, time: 1.2)
        var chord2 = Chord(tab: FMajor, time: 3.1)
        var chord3 = Chord(tab: EMinor, time: 6.2)
        var chord4 = Chord(tab: DMajor, time: 10.6)
        
        var chord5 = Chord(tab: DMajor, time: 13.4)
        var chord6 = Chord(tab: EMinor, time: 14.3)
        var chord7 = Chord(tab: FMajor, time: 16.2)
        var chord8 = Chord(tab: DMajor, time: 17.1)
        
        var chord9 = Chord(tab: CMajor, time: 20.1)
        var chord10 = Chord(tab: CMajor, time: 21.2)
        var chord11 = Chord(tab: EMinor, time: 22.9)
        var chord12 = Chord(tab: DMajor, time: 24.5)
        
        var chord13 = Chord(tab: CMajor, time: 29.2)
        var chord14 = Chord(tab: FMajor, time: 33.5)
        var chord15 = Chord(tab: EMinor, time: 34.2)
        var chord16 = Chord(tab: DMajor, time: 40.1)
        
        chords.append(chord1)
        chords.append(chord2)
        chords.append(chord3)
        chords.append(chord4)
        
        
        chords.append(chord5)
        chords.append(chord6)
        chords.append(chord7)
        chords.append(chord8)
        
        
        chords.append(chord9)
        chords.append(chord10)
        chords.append(chord11)
        chords.append(chord12)
        
        chords.append(chord13)
        chords.append(chord14)
        chords.append(chord15)
        chords.append(chord16)
        
        lyric.addLine(1.21, str: "They Told Him \nDon't You")
        lyric.addLine(3.10, str: "Ever Come Around Here")
        lyric.addLine(6.25, str: "Don't Wanna\n See Your Face")
        lyric.addLine(10.67, str: "You Better Disappear")
        lyric.addLine(13.45, str: "The Fire's In Their Eyes")
        lyric.addLine(14.32, str: "And Their Words Are Really Clear")
        lyric.addLine(16.28, str: "So Beat It, Just Beat It")
        lyric.addLine(25.88, str: "You Better Do What You Can")
        lyric.addLine(30, str: "You Wanna Be Tough")
        lyric.addLine(41.01, str: "Who's Wrong Or Right")
        lyric.addLine(59.88, str: "Showin' How Funky Strong Is Your Fighter")
        lyric.addLine(70.88, str: "It Doesn't Matter Who's Wrong Or Right")
        lyric.addLine(78.08, str: "Showin' How Funky Strong Is Your Fighter")
        lyric.addLine(90.78, str: "So Beat It, Just Beat It")
    }
    
    
    func update(){
        startTime += 0.01
        
        progressBar.value = startTime
        
   
        if activelabels.count > 0 && start+1 < chords.count && abs(startTime - Float(chords[start+1].mTime) + 0.6) < 0.001
        {
            var labels = activelabels.removeAtIndex(0)
            for label in labels {
                UIView.animateWithDuration(0.01 * 60 / Double(speed), animations: {
                    label.alpha = 0
                    }, completion: { finished in
                        label.removeFromSuperview()
                })
            }
            start++
        }
        
        /// Add new chord
        let end = start + activelabels.count
        if end < chords.count && abs(startTime - Float(chords[end].mTime) + rangeOfChords) < 0.001 {
            activelabels.append(createLabels(chords[end].tab.content))
        }
        
        if current + 1 < lyric.lyric.count && abs(startTime - Float(lyric.get(current+1).time)) < 0.001 {
            current++
            label1.text = lyric.get(current).str
            
            if current + 1 < lyric.lyric.count {
                label2.text = lyric.get(current+1).str
                label2.alpha = 0
                UIView.animateWithDuration(0.1, animations: {
                    self.label2.alpha = 1
                })
            }
        }
        
        refresh()
    }
    
    
    func updateAll(time: Float){
        ///Set the start time
        let startTime_int: Int = Int(time*100)
        startTime = Float(startTime_int)/100
        
        ///Remove all label in current screen
        for labels in activelabels{
            for label in labels{
                label.removeFromSuperview()
            }
        }
        activelabels.removeAll(keepCapacity: true)
        
        start = 0;
        var index: Int = 0
        var in_interval = true;
        while in_interval && index < chords.count{
            let chord_time = Float(chords[index].mTime)
            if chord_time > (startTime + rangeOfChords) {
                in_interval = false
            }else if chord_time >= startTime {
                /// Add labels to activelabels
                activelabels.append(createLabels(chords[index].tab.content))
                
                //Set the start value
                if index == 0 || Float(chords[index-1].mTime) < startTime {
                    start = index
                }
            }
            index++
        }
        
        if start > 0 && Float(chords[start].mTime) - startTime > 0.6{
            start--
            activelabels.insert(createLabels(chords[start].tab.content), atIndex: 0)
        }
        
        refresh()
        
        //Update the content of the lyric
        current = -1
        while(current + 1 < lyric.lyric.count){
            if Float(lyric.get(current + 1).time) > startTime {
                break
            }
            current++
        }
        
        if current == -1{
            label1.text = "title of the song"//theSong.title
        }
        else {
            label1.text = lyric.get(current).str
        }
        if current + 1 < lyric.lyric.count {
            label2.text = lyric.get(current+1).str
        }
        else {
            label2.text = "End~"
        }
        
        //update progress view
        var xOffset : CGFloat
        if isTesting {
            xOffset = CGFloat((startTime / Float(audioPlayer.duration)) ) * self.view.frame.width
        }
        else {
            xOffset = CGFloat((startTime / Float(theSong.playbackDuration))) * progressView.frame.width
        }
        println("x offset \(xOffset)")
        progressView.frame = CGRectOffset(progressView.frame, -xOffset, 0)
    }
    
    func setUpSong(){
        var items = [MPMediaItem]()
        items.append(theSong)
        var collection = MPMediaItemCollection(items: items)
        player.setQueueWithItemCollection(collection)
    }
    
    @IBAction func playPause(sender: UIButton) {
       
            if self.isPause{
                startTimer()
                self.isPause = false
                
                if isTesting {
                    audioPlayer.play()
                }else {
                     player.play()
                }
               
                
                sender.setTitle("Pause", forState: .Normal)
            }
            else {
                timer.invalidate()
                self.isPause = true

                
                if isTesting {
                    audioPlayer.pause()
                }else {
                    player.pause()
                }
                sender.setTitle("Continue", forState: .Normal)
            }
    }
    @IBAction func progressBarChanged(sender: UISlider) {
        timer.invalidate()
        updateAll(sender.value)
        if !isPause{
            startTimer()
        }
    }
    
    
    @IBAction func progressBarChangeEnded(sender: UISlider) {
        if isTesting {
            audioPlayer.currentTime = NSTimeInterval(sender.value)
        }else {
            player.currentPlaybackTime = NSTimeInterval(sender.value)
        }

    }
    
    func refresh(){
        /// Change the location of each label
        for var i = 0; i < activelabels.count; ++i{
            var labels = activelabels[i]
            let t = Float(chords[start+i].mTime)
            var yPosition = Float(self.base.frame.height)*(startTime + rangeOfChords - t) / rangeOfChords
            if yPosition > Float(self.base.frame.height){
                yPosition = Float(self.base.frame.height)
            }
            for var j = 0; j < labels.count; ++j{
                var bottom = Float(bottomPoints[j])
                var top = Float(topPoints[j])
                var xPosition = CGFloat(bottom + (top - bottom) * (t - startTime) / rangeOfChords)
                if yPosition == Float(self.base.frame.height){
                    xPosition = bottomPoints[j]
                }
                
                labels[j].center = CGPointMake(xPosition, CGFloat(yPosition - Float(labels[j].frame.height / 2) ))
            }
            //println("\(yPosition) +  \(Float(self.base.frame.height))")
        }
      //  println("Refresh\(startTime)")
    }
    
    func startTimer(){
        timer = NSTimer.scheduledTimerWithTimeInterval(0.01 / Double(speed), target: self, selector: Selector("update"), userInfo: nil, repeats: true)
    }
    
   
    func createLabels(content: String) -> [UILabel]{
        var res = [UILabel]()
        
        for i in 0...count(content)-1{
            let label = UILabel(frame: CGRectMake(0, 0, 0, 0))
            label.font = UIFont.systemFontOfSize(25)
            label.text = String(Array(content)[i])
            label.sizeToFit()
            label.textAlignment = NSTextAlignment.Center
            res.append(label)
            self.base.addSubview(label)
        }
        return res
    }
}