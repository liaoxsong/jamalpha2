
import UIKit
import MediaPlayer
import AVFoundation

let chordwithname:Int = 1
let fullchord:Int = 0
let silverGrey = UIColor(red: 119 / 255, green: 118 / 255, blue: 118 / 255, alpha: 1)

class SongViewController: UIViewController, UIGestureRecognizerDelegate, UIScrollViewDelegate {
    
    // MARK: for testing in simulator
    var isTesting = false
    
    var audioPlayer = AVAudioPlayer()
    let player = MPMusicPlayerController.applicationMusicPlayer()
    
    var songCollection: [MPMediaItem]!
    var songIndex:Int!
    
    var isPause: Bool = true

    //@IBOutlet weak var base: ChordBase!
    @IBOutlet weak var playPauseButton: UIButton!
    
    var pulldownButton:UIButton!
    var tuningButton:UIButton!
    
    var songNameButton: UIButton!
    var artistNameButton: UIButton!
    
    // MARK: Custom views
    var base : ChordBase!
    var chordAndLyricBaseHeight:CGFloat!
    
    //MARK: progress Container
    var progressBlock:UIView!
    var progressBlockContainer:UIView!
    var progressChangedOrigin:CGFloat!
    let progressWidthMultiplier:CGFloat = 2
    var panRecognizer:UIPanGestureRecognizer!
    var isPanning = false
    
    var tapRecognizer: UITapGestureRecognizer!
    
    var verticalBar:UIView!
    var currentTimeLabel:UILabel!
    var totalTimeLabel:UILabel!

    var chords = [Chord]()
    var start: Int = 0
    var activelabels = [[UILabel]]()
    var startTime: TimeNumber = TimeNumber(second: 0, decimal: 0)
    var timer: NSTimer = NSTimer()
    
    var topPoints = [CGFloat]()
    var bottomPoints = [CGFloat]()
    
    var topPointModes = [Int: [CGFloat]]()
    var bottomPointModes = [Int: [CGFloat]]()
    
    var labelHeight:CGSize!
    //speed to control playback speed and
    //corresponding playback speed
    var speed = 1
    
    var rangeOfChords:Float = 5
    
    //Lyric
    var lyricbase: UIView!
    
    var topLyricLabel: UILabel = UILabel()
    var bottomLyricLabel: UILabel = UILabel()
    
    var current: Int = 0    //current line of lyric
    var lyric: Lyric = Lyric()
    
    var mode:Int = 0
    //for displaying 4 buttons, Favorite, Shuffle state, Changed chord version, dots
    var bottomView:UIView!
    
    //Simulate the process of animation for disappearing labels
    let timeToDisappear:Float = 0.6
    var disappearingLabels: [UILabel] = [UILabel]()
    var disapperingLabelAlpha: Int = 0
    
    var favoriateButton:UIButton!
    var shuffleButton:UIButton!
    var guitarButton:UIButton!
    var othersButton:UIButton!
    
    //constant
    let bottomViewHeight:CGFloat = 40 //this is fixed
    let progressContainerHeight:CGFloat = 100 //TODO: Change to percentange
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //hide tab bar
        self.tabBarController?.tabBar.hidden = true
        //load data 载入彩虹吉他谱和歌词
        setUpMoreThanWordsData()
        //setUpRainbowData()
        loadSong()
        setUpBackgroundImage()
        setUpTopButtons()
        setUpNameAndArtistButtons()
        //set up views from top to bottom
        setUpChordBase()
        setUpLyricsBase()
        setUpProgressContainer()
        setUpTimeLabels()
        setUpBottomViewWithButtons()
        //get top and bottom points of six lines
        calculateXPoints()
        playSong()
        
    }
    
    func setUpRainbowData(){
        chords = Chord.getRainbowChords()
        lyric = Lyric.getRainbowLyrics()
    }
    func setUpBackgroundImage(){
        //TODO: use a blured image of current album cover
        self.view.backgroundColor = UIColor(patternImage: UIImage(named: "KP_bg")!)
    }
    
    
    func setUpTopButtons() {
        let buttonCenterY: CGFloat = 25
        pulldownButton = UIButton(frame: CGRect(x: 0, y: 0, width: 75, height: 75))
        //TODO: change image source
        pulldownButton.setImage(UIImage(named: "pulldown"), forState: UIControlState.Normal)
        pulldownButton.sizeToFit()
        pulldownButton.center = CGPoint(x: self.view.frame.width / 12, y: buttonCenterY)
        pulldownButton.addTarget(self, action: "dismissController:", forControlEvents: UIControlEvents.TouchUpInside)
        self.view.addSubview(pulldownButton)
        
        tuningButton = UIButton(frame: CGRect(x: 0 , y: 0, width: 75, height: 75))
        tuningButton.setImage(UIImage(named: "tuning"), forState: UIControlState.Normal)
        tuningButton.sizeToFit()
        tuningButton.center = CGPoint(x: self.view.frame.width * 11 / 12, y: buttonCenterY)
        self.view.addSubview(tuningButton)
    }
    
    func setUpNameAndArtistButtons(){
        songNameButton = UIButton(frame: CGRect(origin: CGPointZero, size: CGSize(width: 0, height: 30)))
        
        artistNameButton = UIButton(frame: CGRect(origin: CGPointZero, size: CGSize(width: 0, height: 20)))
        
        
        if isTesting {
            songNameButton.setTitle("More than words", forState: UIControlState.Normal)
            artistNameButton.setTitle("Extreme", forState: UIControlState.Normal)
            
        }
        else {
            songNameButton.setTitle(songCollection[songIndex].title, forState: UIControlState.Normal)
            artistNameButton.setTitle(songCollection[songIndex].artist, forState: UIControlState.Normal)
        }
        
        artistNameButton.titleLabel?.font = UIFont.systemFontOfSize(13)
        songNameButton.sizeToFit()
        artistNameButton.sizeToFit()
        
        //increase edge width
        //TODO: set a max of width to avoid clashing with pulldown and tuning button
        songNameButton.frame.size = CGSize(width: songNameButton.frame.width + 20, height: 30)
        artistNameButton.frame.size = CGSize(width: artistNameButton.frame.width + 20, height: 30)
        songNameButton.center.x = self.view.frame.width / 2
        songNameButton.center.y = pulldownButton.center.y
        
        artistNameButton.center.x = self.view.frame.width / 2
        artistNameButton.center.y = CGRectGetMaxY(songNameButton.frame) + 20
        
        
        songNameButton.setTitleColor(UIColor.blackColor(), forState: UIControlState.Normal)
        artistNameButton.setTitleColor(UIColor.blackColor(), forState: UIControlState.Normal)
        
        songNameButton.backgroundColor = UIColor(red: 1, green: 1, blue: 1, alpha: 0.5)
        artistNameButton.backgroundColor = UIColor(red: 1, green: 1, blue: 1, alpha: 0.5)
        
        songNameButton.layer.cornerRadius = CGRectGetHeight(songNameButton.frame) / 2
        artistNameButton.layer.cornerRadius = CGRectGetHeight(artistNameButton.frame) / 2
        
        self.view.addSubview(songNameButton)
        self.view.addSubview(artistNameButton)
    }
    
    func dismissController(sender: UIButton) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    

    func setUpMoreThanWordsData(){
        chords = Chord.getExtremeChords()
        lyric = Lyric.getExtremeLyrics()
    }

    func setUpLyricsBase(){
        //Lyric labels
        current = -1
        let sideMargin: CGFloat = 20
        lyricbase = UIView(frame: CGRect(x: sideMargin, y: CGRectGetMaxY(base.frame) + marginBetweenBases, width: self.view.frame.width - 2 * sideMargin, height: chordAndLyricBaseHeight * 0.4))
        lyricbase.backgroundColor = UIColor(red: 1, green: 1, blue: 1, alpha: 0.7)
        self.view.addSubview(lyricbase)
        
        let contentMargin: CGFloat = 5
        
        lyricbase.layer.cornerRadius = 20
        
        topLyricLabel.frame = CGRectMake(contentMargin, 0, lyricbase.frame.width - 2 * contentMargin, 2 * lyricbase.frame.height / 3)
        topLyricLabel.center.y = lyricbase.frame.height / 3
        topLyricLabel.numberOfLines = 2
        topLyricLabel.textAlignment = NSTextAlignment.Center
        topLyricLabel.font = UIFont.systemFontOfSize(23)
        topLyricLabel.lineBreakMode = .ByWordWrapping
        topLyricLabel.textColor = silverGrey
        lyricbase.addSubview(topLyricLabel)
        
        bottomLyricLabel.frame = CGRectMake(contentMargin, 0, lyricbase.frame.width - 2 * contentMargin, lyricbase.frame.height / 3)
        bottomLyricLabel.center.y =  2 * lyricbase.frame.height / 3 + 10
        bottomLyricLabel.numberOfLines = 2
        bottomLyricLabel.textAlignment = NSTextAlignment.Center
        bottomLyricLabel.font = UIFont.systemFontOfSize(16)
        bottomLyricLabel.lineBreakMode = .ByWordWrapping
        bottomLyricLabel.textColor = silverGrey
        lyricbase.addSubview(bottomLyricLabel)
    }
    
    let marginBetweenBases: CGFloat = 15
    
    func setUpChordBase(){
        let marginToArtistButton: CGFloat = 15
        chordAndLyricBaseHeight = self.view.frame.height - CGRectGetMaxY(artistNameButton.frame) - marginToArtistButton - bottomViewHeight - progressContainerHeight - marginBetweenBases
        base = ChordBase(frame: CGRect(x: 0, y: CGRectGetMaxY(artistNameButton.frame) + marginToArtistButton, width: self.view.frame.width * 0.68, height: chordAndLyricBaseHeight * 0.6))
        base.center.x = self.view.center.x
        base.backgroundColor = UIColor.clearColor()
        self.view.addSubview(base)
    }
    
    func loadSong(){
        if isTesting {
            setUpTestSong()
        }
        else {
            setUpSong()
        }
    }
    
    func playSong(){
        isPause = false
        if isTesting {
            //we are always coming back to the same song
            if audioPlayer.currentTime > 0  { //if already started playing
                startTime = TimeNumber(time: Float(audioPlayer.currentTime))
                updateAll(startTime.toDecimalNumer())
                startTimer()
            } else {
                updateAll(0)
                startTimer()
                audioPlayer.play()
            }
        }
        else{ //if not testing

            //the player is not null
            if let currentSong = player.nowPlayingItem {
                //if we are coming back for the same song
                if currentSong == songCollection[songIndex] {
                    
                    startTime =  TimeNumber(time: Float(player.currentPlaybackTime))
                    updateAll(startTime.toDecimalNumer())
                }
                else { //if not the same song
                    updateAll(0)
                }
            }
            else {
            //player hasn't started yet
                updateAll(0)
            }
            
            startTimer()
            player.play()
        }
    }
    func setUpProgressContainer(){
        
        progressChangedOrigin = self.view.frame.width / 2
        progressBlockContainer = UIView(frame: CGRect(x: 0, y: 0, width: self.view.frame.width, height: progressContainerHeight))
        
        progressBlockContainer.center.y = self.view.frame.height - bottomViewHeight - progressContainerHeight / 2
        
        progressBlockContainer.backgroundColor = UIColor.clearColor()
        self.view.addSubview(progressBlockContainer)
        
        var blockWidth:CGFloat
        if isTesting {
            blockWidth = CGFloat(audioPlayer.duration) * progressWidthMultiplier
        } else {
            blockWidth = CGFloat(songCollection[songIndex].playbackDuration) * progressWidthMultiplier
        }
        
        progressBlock = UIView(frame: CGRect(x: progressChangedOrigin, y: 0, width: blockWidth, height: 5))
        progressBlock.center.y = progressContainerHeight / 2
        progressBlock.backgroundColor = mainPinkColor
        progressBlockContainer.addSubview(progressBlock)
        panRecognizer = UIPanGestureRecognizer(target: self, action:Selector("handlePan:"))
        panRecognizer.delegate = self
        progressBlockContainer.addGestureRecognizer(panRecognizer)
        tapRecognizer = UITapGestureRecognizer(target: self, action: Selector("playPause:"))
        progressBlockContainer.addGestureRecognizer(tapRecognizer)
        
    }
    
    func handlePan(recognizer: UIPanGestureRecognizer) {
        let translation = recognizer.translationInView(self.view)
        for childview in recognizer.view!.subviews {
            let child = childview as! UIView
            self.isPanning = true
            
            var newPosition = progressChangedOrigin + translation.x
            
            // leftmost point of inner bar cannot be more than half of the view
            if newPosition > self.view.frame.width / 2 {
                newPosition = self.view.frame.width / 2
            }
            
            // the end of inner bar cannot be smaller left half of view
            if newPosition + child.frame.width < self.view.frame.width / 2 {
                newPosition = self.view.frame.width / 2 - child.frame.width
            }
            
            //update all chords, lyrics
            timer.invalidate()
            
            //new Position from 160 to -357
            //-self.view.frame.width /2 
            //= from 0 ot -517
            //divide by -2: from 0 to 258
            let toTime = Float(newPosition - self.view.frame.width / 2) / -Float(self.progressWidthMultiplier)
            //258  517
            updateAll(toTime)
            if !isPause {
                startTimer()
            }
            child.frame.origin.x = newPosition
            
            //when finger is lifted
            if recognizer.state == UIGestureRecognizerState.Ended {
                progressChangedOrigin = newPosition
                isPanning = false
                if isTesting {
                    audioPlayer.currentTime = NSTimeInterval(toTime)
                }
                else {
                    player.currentPlaybackTime = NSTimeInterval(toTime)
                
                }
            }
        }
    }
    
    
    
    func setUpTimeLabels(){
        verticalBar = UIView(frame: CGRect(x: 0, y: 0, width: 1, height: progressContainerHeight / 2))
        verticalBar.center = progressBlockContainer.center
        verticalBar.backgroundColor = UIColor.blueColor()
        self.view.addSubview(verticalBar)
        
        currentTimeLabel = UILabel(frame: CGRect(x: 0, y: progressBlockContainer.frame.origin.y, width: 100, height: 30))
        
        currentTimeLabel.font = UIFont.systemFontOfSize(10)
        currentTimeLabel.text = "0:00.00"
        currentTimeLabel.textColor = UIColor.blueColor()
        self.view.addSubview(currentTimeLabel)
        
        totalTimeLabel = UILabel(frame: CGRect(x: self.view.frame.width - 50, y: progressBlockContainer.frame.origin.y, width: 0, height: 30))
        totalTimeLabel.textColor = UIColor.blackColor()
        totalTimeLabel.font = UIFont.systemFontOfSize(10)
        
        if isTesting {
         totalTimeLabel.text = TimeNumber(time: Float(audioPlayer.duration)).toDisplayString()
        } else {
         totalTimeLabel.text = TimeNumber(time: Float(songCollection[songIndex].playbackDuration)).toDisplayString()
        }
        
        totalTimeLabel.sizeToFit()
        totalTimeLabel.center.x = self.view.frame.width - totalTimeLabel.frame.width / 2 - 5
        self.view.addSubview(totalTimeLabel)
        
    }

    //from left to right: share, favoriate, shuffle, others
    func setUpBottomViewWithButtons(){
        let edgeButtonSideMargin:CGFloat = 50
        bottomView = UIView(frame: CGRect(x: 0, y: self.view.frame.height - bottomViewHeight, width: self.view.frame.width, height: bottomViewHeight))
        bottomView.backgroundColor = UIColor.blackColor()
        bottomView.alpha = 0.6
        self.view.addSubview(bottomView)
        
        //TODO: Add glowing effect when pressed
        //divide view width into eigth to distribute center x for each of four buttons
        favoriateButton = UIButton(frame: CGRect(x: 0, y: 0, width: 50, height: 50))
        favoriateButton.setImage(UIImage(named: "notfavorited"), forState: UIControlState.Normal)
        favoriateButton.sizeToFit()
        

        shuffleButton = UIButton(frame: CGRect(x: 0, y: 0, width: 50, height: 50))
        shuffleButton.setImage(UIImage(named: "loop_playlist"), forState: UIControlState.Normal)
        shuffleButton.sizeToFit()
        
        guitarButton = UIButton(frame: CGRect(x: 0, y: 0, width: 50, height: 50))
        guitarButton.setImage((UIImage(named: "guitar_settings")), forState: UIControlState.Normal)
        guitarButton.sizeToFit()
        guitarButton.addTarget(self, action: "showGuitarActions", forControlEvents: UIControlEvents.TouchUpInside)
        
        othersButton = UIButton(frame: CGRect(x: 0, y: 0, width: 50, height: 50))
        othersButton.setImage(UIImage(named: "more_options"), forState: UIControlState.Normal)
        othersButton.sizeToFit()
        othersButton.center.y = bottomViewHeight / 2
        othersButton.addTarget(self, action: "showActionSheet", forControlEvents: UIControlEvents.TouchUpInside)
        
        var bottomButtons = [favoriateButton, shuffleButton, guitarButton, othersButton]
        var orderIndex: [CGFloat] = [1, 3, 5 , 7]//1/8, 3/8, 5/8, 7/8 of the width
        let eigthOfWidth = self.bottomView.frame.width / 8
        favoriateButton.center.x = eigthOfWidth
        favoriateButton.center.y = bottomViewHeight / 2
        bottomView.addSubview(favoriateButton)
        
        for i in 0...3{
            bottomButtons[i].center.x = orderIndex[i] * eigthOfWidth
            bottomButtons[i].center.y = bottomViewHeight / 2
            bottomView.addSubview(bottomButtons[i])
        }
    }
    
    func showGuitarActions(){
        let optionMenu = UIAlertController(title: nil, message: nil, preferredStyle: .ActionSheet)
        
        let changeTabsMode = UIAlertAction(title: "Change Tab Mode", style: .Default, handler: {
            (alert:UIAlertAction!) -> Void in
            self.changeChordMode()
        })
        let cancelAction = UIAlertAction(title: "Cancel", style: .Cancel, handler:nil)
        
        optionMenu.addAction(changeTabsMode)
        optionMenu.addAction(cancelAction)
        self.presentViewController(optionMenu, animated: true, completion: nil)
        
    }
    func showActionSheet(){
        let optionMenu = UIAlertController(title: nil, message: nil, preferredStyle: .ActionSheet)
        

        
        let addTabsAction = UIAlertAction(title: "Add your tabs", style: .Default, handler: {
            (alert:UIAlertAction!) -> Void in
            
            let editTabsVC = EditTabsViewController()
            self.presentViewController(editTabsVC, animated: true, completion: nil)
            //Go to edit tabs screen
            
        })
        
        let addLyricsAction = UIAlertAction(title: "Add your lyrics", style: .Default, handler: {
            (alert:UIAlertAction!) -> Void in
            //TODO: Go to edit lyrics screens
            
        })
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .Cancel, handler:nil)
        optionMenu.addAction(addTabsAction)
        optionMenu.addAction(addLyricsAction)
        optionMenu.addAction(cancelAction)
        
        self.presentViewController(optionMenu, animated: true, completion: nil)
    }

    func setUpTestSong(){
        if var filePath = NSBundle.mainBundle().pathForResource("more",ofType:"mp3"){
            var fileWithPath = NSURL.fileURLWithPath(filePath)
            audioPlayer = AVAudioPlayer(contentsOfURL: fileWithPath, error: nil)
        }
        else{
            NSLog("mp3 not found")
        }
        audioPlayer.prepareToPlay()
    }
    
    override func prefersStatusBarHidden() -> Bool {
        return true
    }
    
    //stop timer,stop refreshing UIs after view is completely gone of sight
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        println("view will disappear")
        timer.invalidate()
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        self.navigationController?.navigationBar.tintColor = mainPinkColor
        self.tabBarController?.tabBar.hidden = false
    }
    
    func calculateXPoints(){
        let width = base.frame.width
        
        let margin:Float = 0.25
        let initialPoint:CGFloat = CGFloat(Float(width) * margin)
        let rightTopPoint:CGFloat = CGFloat(Float(width) * (1 - margin))
        
        let scale:Float = 1 / 12
        let topWidth = Float(rightTopPoint) - Float(initialPoint)
        let topLeft = Float(initialPoint) + Float(topWidth) * scale
        topPoints = [CGFloat](count: 7, repeatedValue: 0)
        
        topPoints[0] = CGFloat(topLeft)
        for i in 1..<6 {
            topPoints[i] = CGFloat(Float(topPoints[i - 1]) + Float(topWidth * scale * 2))
        }
        
        bottomPoints = [CGFloat](count: 7, repeatedValue: 0)
        bottomPoints[0] = CGFloat(Float(width) * scale)
        for i in 1..<6 {
            bottomPoints[i] = CGFloat(Float(bottomPoints[i - 1]) + Float(width) * scale * 2)
        }

        //add things
        let top0: CGFloat = CGFloat(margin * Float(base.frame.width) - 20)
        let buttom0: CGFloat = CGFloat(-20)
        
        topPoints.insert(top0, atIndex: 0)
        bottomPoints.insert(buttom0, atIndex: 0)
        
        //Mode 0
        topPointModes[0] = topPoints
        bottomPointModes[0] = bottomPoints
        
        //Mode 1
        topPoints = [width / 2]
        bottomPoints = [width / 2]
        
        topPointModes[1] = topPoints
        bottomPointModes[1] = bottomPoints
        
        topPoints = topPointModes[mode]!
        bottomPoints = bottomPointModes[mode]!

    }

    
    func update(){

        startTime.addMinimal()
        println("update:\(startTime.toDecimalNumer())")
        if activelabels.count > 0 && start+1 < chords.count && chords[start+1].mTime.isEqual(TimeNumber( time: startTime.toDecimalNumer() + timeToDisappear))
        {
            for label in disappearingLabels {
                label.removeFromSuperview()
            }
            
            disappearingLabels = activelabels.removeAtIndex(0)
            disapperingLabelAlpha = Int(timeToDisappear / 0.01)
            
            start++
        }
        
        // Add new chord
        let end = start + activelabels.count
        if end < chords.count && chords[end].mTime.isEqual(TimeNumber(time: rangeOfChords + startTime.toDecimalNumer())) {
            activelabels.append(createLabels(chords[end].tab.name, content: chords[end].tab.content))
        }
        
        if current + 1 < lyric.lyric.count && lyric.get(current+1).time.isEqual(startTime) {
            current++
            topLyricLabel.text = lyric.get(current).str
            
            if current + 1 < lyric.lyric.count {
                bottomLyricLabel.text = lyric.get(current+1).str
                
//                UIView.animateWithDuration(0.1, animations: {
//                    self.label2.alpha = 1
//                })
            }
        }
        
        if disapperingLabelAlpha > 0 {
            let totalalpha: Float = timeToDisappear / 0.01
            let currentalpha: CGFloat = CGFloat(Float(disapperingLabelAlpha) / totalalpha)
            disapperingLabelAlpha--
            for label in disappearingLabels {
                label.alpha = currentalpha
                if disapperingLabelAlpha == 0 {
                    label.removeFromSuperview()
                }
            }
        }
        
        refreshChordLabel()
        refreshProgressBlock()
        refreshTimeLabel()
        
    }
    
    
    func refreshChordLabel(){
        /// Change the location of each label
        for var i = 0; i < activelabels.count; ++i{
            var labels = activelabels[i]
            let t = chords[start+i].mTime
            var yPosition = Float(self.base.frame.height)*(startTime.toDecimalNumer() + rangeOfChords - t.toDecimalNumer()) / rangeOfChords
            if yPosition > Float(self.base.frame.height){
                yPosition = Float(self.base.frame.height)
            }
            for var j = 0; j < labels.count; ++j{
                var bottom = Float(bottomPoints[j])
                var top = Float(topPoints[j])
                var xPosition = CGFloat(bottom + (top - bottom) * (t.toDecimalNumer() - startTime.toDecimalNumer()) / rangeOfChords)
                if yPosition == Float(self.base.frame.height){
                    xPosition = bottomPoints[j]
                }
                
                labels[j].center = CGPointMake(xPosition, CGFloat(yPosition - Float(labels[j].frame.height / 2)))
            }
        }
        
    }
    
    func refreshProgressBlock(){
        var barWidth:CGFloat
        
        if isTesting {
            barWidth = CGFloat(audioPlayer.duration)
        }
        else {
            barWidth = CGFloat(songCollection[songIndex].playbackDuration)
        }
        
        let newOriginX = self.view.frame.width / 2 - CGFloat(startTime.toDecimalNumer()) * self.progressBlock.frame.width / barWidth
        if !isPanning {
            self.progressChangedOrigin = newOriginX
        }
        
        self.progressBlock.frame.origin.x = newOriginX
    }
    
    
    
    func refreshTimeLabel(){
        //update current time label
        currentTimeLabel.text = startTime.toDisplayString()
    }
    
    func updateAll(time: Float){
        ///Set the start time
        startTime = TimeNumber(time: time)
        
        ///Remove all label in current screen
        for labels in activelabels{
            for label in labels{
                label.removeFromSuperview()
            }
        }
        activelabels.removeAll(keepCapacity: true)
        
        //find the start of the chord whose time is larger than current time
        start = 0
        var last: Int = 0 //the end index of the chord that would show on the screen
        
        var begin: Int = 0
        var end: Int = chords.count - 1
        
        while true {
            var mid: Int = (begin + end) / 2
            if startTime.isLongerThan(chords[mid].mTime) {
                begin = mid
            } else {
                end = mid
            }
            if begin == (end - 1) {
                start = begin
                if startTime.isLongerThan(chords[end].mTime) {
                    start = end
                }
                break
            }
        }
        
        begin = 0
        end = chords.count - 1
        let tn = TimeNumber(time: startTime.toDecimalNumer() + rangeOfChords)
        while true {
            var mid: Int = (begin + end) / 2
            if tn.isLongerThan(chords[mid].mTime) {
                begin = mid
            } else {
                end = mid
            }
            if begin == (end - 1) {
                last = begin
                if tn.isLongerThan( chords[end].mTime ) {
                    last = end
                }
                break
            }
        }

        if start == last {
            activelabels.append(createLabels(chords[start].tab.name, content: chords[start].tab.content))
        }
        
        if start < last {
            if startTime.isLongerThan(chords[start].mTime) && (TimeNumber(time: startTime.toDecimalNumer() + timeToDisappear)).isLongerThan(chords[start+1].mTime) {
                self.start++
            }
            
            for i in start...last {
                activelabels.append(createLabels(chords[i].tab.name, content: chords[i].tab.content))
            }
        }
        
        refreshChordLabel()
        
        //Update the content of the lyric
        current = -1
        while(current + 1 < lyric.lyric.count){
            if lyric.get(current + 1).time.toDecimalNumer() > startTime.toDecimalNumer() {
                break
            }
            current++
        }
        
        if current == -1{
            topLyricLabel.text = "..."//theSong.title
        }
        else {
            topLyricLabel.text = lyric.get(current).str
        }
        if current + 1 < lyric.lyric.count {
            bottomLyricLabel.text = lyric.get(current+1).str
        }
        else {
            bottomLyricLabel.text = "End~"
        }

    }
    
    func setUpSong(){
        //songCollection comes in as ["A","B","C","D","E"]
        //but we are playing an item with a selected index for example index 2,i.e. item:C
        //so we need to sort it to be ["C","D","E","A","B"]
        var rearrangedCollection:[MPMediaItem] = [MPMediaItem]()
        
        for i in songIndex..<songCollection.count {
            rearrangedCollection.append(songCollection[i])
        }
        for i in 0..<songIndex {
            rearrangedCollection.append(songCollection[i])
        }
        
        var collection = MPMediaItemCollection(items: rearrangedCollection)
        player.setQueueWithItemCollection(collection)

    }
    
    func playPause(recognizer: UITapGestureRecognizer) {
            if isPause{
                startTimer()
                isPause = false
                if isTesting {
                    audioPlayer.play()
                }else {
                     player.play()
                }
            }
            else {
                timer.invalidate()
                isPause = true
                if isTesting {
                    audioPlayer.pause()
                }else {
                    player.pause()
                }
            }
    }
    
    func changeChordMode() {
        timer.invalidate()
        mode = 1 - mode
        topPoints = topPointModes[mode]!
        bottomPoints = bottomPointModes[mode]!
        updateAll(startTime.toDecimalNumer())
        if !isPause{
            startTimer()
        }
    }

    func startTimer(){
        timer = NSTimer.scheduledTimerWithTimeInterval(0.01 / Double(speed), target: self, selector: Selector("update"), userInfo: nil, repeats: true)
    }
    
    
    func createLabels(name: String, content: String) -> [UILabel]{
        var res = [UILabel]()
        
        let label = UILabel(frame: CGRectMake(0, 0, 0, 0))
        label.font = UIFont.systemFontOfSize(25)
        label.text = name
        label.sizeToFit()
        label.textAlignment = NSTextAlignment.Center
        res.append(label)
        self.base.addSubview(label)
        
        if mode == fullchord {
            for i in 0...count(content)-1 {
                let label = UILabel(frame: CGRectMake(0, 0, 0, 0))
                label.font = UIFont.systemFontOfSize(25)
                label.text = String(Array(content)[i])
                label.sizeToFit()
                label.textAlignment = NSTextAlignment.Center
                res.append(label)
                self.base.addSubview(label)
        }
        }
        return res
    }
}