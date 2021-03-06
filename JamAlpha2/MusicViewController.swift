import UIKit
import MediaPlayer
import Haneke


class MusicViewController: UIViewController, UITableViewDataSource, UITableViewDelegate  {

    @IBOutlet weak var tableView: UITableView!
    
    var uniqueSongs = [MPMediaItem]()
    private var uniqueArtists = [SimpleArtist]()
    private var uniqueAlbums = [SimpleAlbum]()
    
    var demoSongs = [AVPlayerItem]()
    
    private var songsByFirstAlphabet = [(String, [MPMediaItem])]()
    private var artistsByFirstAlphabet = [(String, [SimpleArtist])]()
    private var albumsByFirstAlphabet = [(String, [SimpleAlbum])]()
    
    //a single array (sorted by alphabets) used for didSelectRow
    private var songsSorted = [MPMediaItem] ()
    private var artistsSorted = [SimpleArtist]()
    private var albumsSorted = [SimpleAlbum]()
    
    private var rwLock = pthread_rwlock_t()
    
    var pageIndex = 0
    var searchAPI:SearchAPI! = SearchAPI()
    var isSeekingPlayerState = false
    
    var queueSuspended = false
    var viewDidAppear = false
    
    @IBOutlet weak var musicTable: UITableView!
    
    //for transition view animator
    var animator: CustomTransitionAnimation?
    
    var songCount: Int64 = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        pthread_rwlock_init(&rwLock, nil)
        loadData()
        createTransitionAnimation()
       
        UITableView.appearance().sectionIndexColor = UIColor.mainPinkColor()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        NetworkManager.sharedInstance.tableView = self.musicTable
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        viewDidAppear = true
        musicTable.reloadData()
    }
    
    func clearData() {
        uniqueSongs.removeAll()
        uniqueArtists.removeAll()
        uniqueAlbums.removeAll()
        songsByFirstAlphabet = [(String, [MPMediaItem])]()
        artistsByFirstAlphabet = [(String, [SimpleArtist])]()
        albumsByFirstAlphabet = [(String, [SimpleAlbum])]()
        songsSorted.removeAll()
        albumsSorted.removeAll()
        artistsSorted.removeAll()
        
    }
    
    func loadData() {
        clearData()
        uniqueSongs = MusicManager.sharedInstance.uniqueSongs
        uniqueArtists = MusicManager.sharedInstance.uniqueArtists
        uniqueAlbums = MusicManager.sharedInstance.uniqueAlbums
        demoSongs = MusicManager.sharedInstance.demoSongs
        
        songsByFirstAlphabet = MusicManager.sharedInstance.songsByFirstAlphabet
        artistsByFirstAlphabet = MusicManager.sharedInstance.artistsByFirstAlphabet
        albumsByFirstAlphabet = MusicManager.sharedInstance.albumsByFirstAlphabet
        
        songsSorted = MusicManager.sharedInstance.songsSorted
        artistsSorted = MusicManager.sharedInstance.artistsSorted
        albumsSorted = MusicManager.sharedInstance.albumsSorted
        
        musicTable.reloadData()
    }
    
    
    deinit{
        pthread_rwlock_destroy(&rwLock)
    }

    func registerNotifications(){
        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("currentSongChanged:"), name: MPMusicPlayerControllerNowPlayingItemDidChangeNotification, object: MusicManager.sharedInstance.player)
    }
    
    
    func synced(lock: AnyObject, closure: () -> ()) {
        objc_sync_enter(lock)
        closure()
        objc_sync_exit(lock)
    }
    
    func currentSongChanged(notification: NSNotification){
        synced(self) {
            let player = MusicManager.sharedInstance.player
            if player.repeatMode == .One {
                return
            }
            if player.nowPlayingItem != nil {
                if player.indexOfNowPlayingItem != MusicManager.sharedInstance.lastSelectedIndex {
                    if !self.isSeekingPlayerState {
                        self.musicTable.reloadData()
                    }
                }
            }
        }
    }

    func createTransitionAnimation(){
        if(animator == nil){
            self.animator = CustomTransitionAnimation()
        }
    }
    
    func popToCurrentSong(){
        let songVC = self.storyboard?.instantiateViewControllerWithIdentifier("songviewcontroller") as! SongViewController
        
        if MusicManager.sharedInstance.avPlayer.currentItem != nil {
            songVC.isDemoSong = true
        }
      
        songVC.selectedFromTable = false
        songVC.transitioningDelegate = self.animator
        self.animator!.attachToViewController(songVC)
        self.navigationController!.presentViewController(songVC, animated: true, completion: nil)
    }
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        if pageIndex == 0  {
            if NSUserDefaults.standardUserDefaults().boolForKey(kShowDemoSong) {
                return 1 + songsByFirstAlphabet.count
            }
            return songsByFirstAlphabet.count
        }
        else if pageIndex == 1 {
            return artistsByFirstAlphabet.count
        }
        else {
            return albumsByFirstAlphabet.count
        }
    }
    
    // populate the index titles on the right side of screen
    func sectionIndexTitlesForTableView(tableView: UITableView) -> [String]? {
        var titles = [String]()
        if pageIndex == 0 {
            for (firstAlphabet, _) in songsByFirstAlphabet {
                titles.append(firstAlphabet)
            }
            return titles
        } else if pageIndex == 1 {
            for (firstAlphabet, _) in artistsByFirstAlphabet {
                titles.append(firstAlphabet)
            }
            return titles
        } else {
            for (firstAlphabet, _) in albumsByFirstAlphabet {
                titles.append(firstAlphabet)
            }
            return titles
        }
    }
    
    // scroll to the current section
    func tableView(tableView: UITableView, sectionForSectionIndexTitle title: String, atIndex index: Int) -> Int {
        if pageIndex == 0 {
            for i in 0..<songsByFirstAlphabet.count {
                if title == songsByFirstAlphabet[i].0 {
                    return i
                }
            }
        } else if pageIndex == 1 {
            for i in 0..<artistsByFirstAlphabet.count {
                if title == artistsByFirstAlphabet[i].0 {
                    return i
                }
            }
        } else {
            for i in 0..<albumsByFirstAlphabet.count {
                if title == albumsByFirstAlphabet[i].0 {
                    return i
                }
            }
        }
        return 0
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if pageIndex == 0  {
            if NSUserDefaults.standardUserDefaults().boolForKey(kShowDemoSong) {
                if section == 0 {
                    return demoSongs.count
                } else {
                    return songsByFirstAlphabet[section-1].1.count
                }
            }
            return songsByFirstAlphabet[section].1.count
        }
        else if pageIndex == 1 {
            return artistsByFirstAlphabet[section].1.count
        }
        else
        {
            return albumsByFirstAlphabet[section].1.count
        }
    }

    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("musiccell", forIndexPath: indexPath) as! MusicCell
        cell.demoImage.hidden = true
        cell.cloudImage.hidden = true
        
        if pageIndex == 0 {
    
            var song: Findable!
            
            if NSUserDefaults.standardUserDefaults().boolForKey(kShowDemoSong) {
                if indexPath.section == 0 {
                    song = demoSongs[indexPath.row]
                    cell.demoImage.hidden = false
                } else {
                    //section starts at 1 if we have demo songs
                    song = songsByFirstAlphabet[indexPath.section-1].1[indexPath.row]
                }
                
            } else {
                song = songsByFirstAlphabet[indexPath.section].1[indexPath.row]
            }
            
            cell.mainTitle.text = song.getTitle()
            cell.subtitle.text = song.getArtist()
            
            cell.titleTrailingConstraint.constant = 12
            cell.loudspeakerImage.hidden = true
            
            if MusicManager.sharedInstance.player.nowPlayingItem != nil && MusicManager.sharedInstance.avPlayer.currentItem == nil {
                if let item = song as? MPMediaItem {
                    if item == MusicManager.sharedInstance.player.nowPlayingItem {
                        cell.titleTrailingConstraint.constant = 50
                        cell.loudspeakerImage.hidden = false
                    }
                }
            }
            
            if let _ = song.getURL() {
                cell.cloudImage.hidden = true
                cell.titleLeftConstraint.constant = 11
            } else {
                cell.cloudImage.hidden = false
                cell.titleLeftConstraint.constant = 30
            }
            
            if let cover = song.getArtWork() { //if this item has artwork
                cell.coverImage.image = cover.imageWithSize(CGSize(width: 54, height: 54))
            } else if let cover = CoreDataManager.getCoverImage(song) {//then we try to find the cover we saved from iTunes last time we searched it
                cell.coverImage.image = cover
            } else { //find the cover in iTunes
                cell.coverImage.image = UIImage(named: DEFAULT_COVER)
                CoreDataManager.initializeSongToDatabase(song)
                loadAPISearchImageToCell(cell, song: song, imageSize: SearchAPI.ImageSize.Thumbnail)
            }
            
        } else if pageIndex == 1  {
            
            let theArtist = artistsByFirstAlphabet[indexPath.section].1[indexPath.row]
            
            cell.coverImage.image = nil
            cell.imageWidth.constant = 80
            cell.imageHeight.constant = 80
            
            let song = theArtist.songCollection.representativeItem!
            
            if let cover = theArtist.getArtwork() {
                let image = cover.imageWithSize(CGSize(width: 80, height: 80))
                cell.coverImage.image = image
            } else if let cover = CoreDataManager.getCoverImage(song) {
                cell.coverImage.image = cover
            } else {
                cell.coverImage.image = UIImage(named: DEFAULT_COVER)
                 loadAPISearchImageToCell(cell, song: song, imageSize: SearchAPI.ImageSize.Thumbnail)
            }
        
            
            cell.loudspeakerImage.hidden = true
            let numberOfTracks = theArtist.songCollection.items.count
            let trackPrompt = "track".addPluralSubscript(numberOfTracks)
            
            cell.mainTitle.text = theArtist.getArtist()
            cell.subtitle.text = "\(numberOfTracks) \(trackPrompt)"
            
        } else if pageIndex == 2 {

            let theAlbum = albumsByFirstAlphabet[indexPath.section].1[indexPath.row]
            cell.imageWidth.constant = 80
            cell.imageHeight.constant = 80
            
            let song = theAlbum.songCollection.items[0]
            
            if let cover = theAlbum.getArtwork() {
                let image = cover.imageWithSize(CGSize(width: 80, height: 80))
                cell.coverImage.image = image
            } else if let cover = CoreDataManager.getCoverImage(song) {
                cell.coverImage.image = cover
            } else {
                cell.coverImage.image = UIImage(named: DEFAULT_COVER)
                loadAPISearchImageToCell(cell, song: song, imageSize: SearchAPI.ImageSize.Thumbnail)
            }
        
            cell.loudspeakerImage.hidden = true
            cell.mainTitle.text = theAlbum.getAlbumTitle()
            cell.subtitle.text = theAlbum.getArtist()
        }
        return cell
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        if pageIndex == 0 {
        
            return 60
        }
        else if pageIndex == 1 {
        
            return 100
        }
        else if pageIndex == 2 {
            return 100
        }
        //will never get here
        return 0
    }
   
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        var isDemoSong = false
        isSeekingPlayerState = true
        
        if pageIndex == 0 {
            let songVC = self.storyboard?.instantiateViewControllerWithIdentifier("songviewcontroller") as! SongViewController
            var indexToBePlayed:Int = 0
            if NSUserDefaults.standardUserDefaults().boolForKey(kShowDemoSong) {
                if indexPath.section == 0 {
                    MusicManager.sharedInstance.setDemoSongQueue(demoSongs, selectedIndex: indexPath.row)
                    songVC.selectedRow = indexPath.row
                    MusicManager.sharedInstance.player.pause()
                    MusicManager.sharedInstance.player.currentPlaybackTime = 0
                    songVC.isDemoSong = true
                    isDemoSong = true
                    if (KAVplayer != nil && KAVplayer.rate > 0){
                        KAVplayer.rate = 0
                        KAVplayer = nil
                    }
                    
                } else {
                    MusicManager.sharedInstance.setPlayerQueue(songsSorted)
                    indexToBePlayed = findIndexToBePlayed(songsByFirstAlphabet, section: indexPath.section-1, currentRow: indexPath.row)
                    MusicManager.sharedInstance.setIndexInTheQueue(indexToBePlayed)
                    MusicManager.sharedInstance.avPlayer.pause()
                    MusicManager.sharedInstance.avPlayer.seekToTime(kCMTimeZero)
                    MusicManager.sharedInstance.avPlayer.removeAllItems()
                    
                }
                
            } else {
                MusicManager.sharedInstance.setPlayerQueue(songsSorted)
                indexToBePlayed = findIndexToBePlayed(songsByFirstAlphabet, section: indexPath.section, currentRow: indexPath.row)
                MusicManager.sharedInstance.setIndexInTheQueue(indexToBePlayed)
                MusicManager.sharedInstance.avPlayer.pause()
                MusicManager.sharedInstance.avPlayer.seekToTime(kCMTimeZero)
                MusicManager.sharedInstance.avPlayer.removeAllItems()
            }
            
            //We use a background thread to constantly check player's current playing item, and we only pop up
            if(!isDemoSong && songsSorted.count > 0 && (songsSorted[indexToBePlayed]).cloudItem && NetworkManager.sharedInstance.reachability.isReachableViaWWAN()) {
                dispatch_async((dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0))) {
                    while (self.isSeekingPlayerState) {
                        if(MusicManager.sharedInstance.player.indexOfNowPlayingItem != MusicManager.sharedInstance.lastSelectedIndex){
                            MusicManager.sharedInstance.player.stop()
                            KGLOBAL_nowView.stop()
                            KGLOBAL_nowView_topSong.stop()
                            dispatch_async(dispatch_get_main_queue()) {
                                self.showCellularEnablesStreaming(tableView)
                            }
                            self.isSeekingPlayerState = false
                            
                            break
                        }
                        
                        if(MusicManager.sharedInstance.player.indexOfNowPlayingItem == MusicManager.sharedInstance.lastSelectedIndex && MusicManager.sharedInstance.player.playbackState != .SeekingForward){
                            if(MusicManager.sharedInstance.player.nowPlayingItem != nil){
                                dispatch_async(dispatch_get_main_queue()) {
                                    songVC.selectedFromTable = true
                                    songVC.transitioningDelegate = self.animator
                                    self.animator!.attachToViewController(songVC)
                                    
                                    self.presentViewController(songVC, animated: true, completion: {
                                        completed in
                                        //reload table to show loudspeaker icon on current selected row
                                        tableView.reloadData()
                                    })
                                }
                                self.isSeekingPlayerState = false
                                break
                            }
                        }
                    }
                }
            } else if (isDemoSong || NetworkManager.sharedInstance.reachability.isReachableViaWiFi() || !songsSorted[indexToBePlayed].cloudItem ){
                isSeekingPlayerState = false
                if(!isDemoSong){
                    if(MusicManager.sharedInstance.player.nowPlayingItem == nil){
                        MusicManager.sharedInstance.player.play()
                    }
                }
                
                songVC.selectedFromTable = true
                songVC.transitioningDelegate = self.animator
                self.animator!.attachToViewController(songVC)
                
                self.presentViewController(songVC, animated: true, completion: {
                    completed in
                    //reload table to show loudspeaker icon on current selected row
                    tableView.reloadData()
                })
            } else if ( songsSorted.count > 0 && !NetworkManager.sharedInstance.reachability.isReachable() && songsSorted[indexToBePlayed].cloudItem) {
                isSeekingPlayerState = false
                MusicManager.sharedInstance.player.stop()
                self.showConnectInternet(tableView)
            }
            //////////////////////////////////////////////////////////
        }
        else if pageIndex == 1 {
            isSeekingPlayerState = false
            let indexToBePlayed = findIndexToBePlayed(artistsByFirstAlphabet, section: indexPath.section, currentRow: indexPath.row)
            let artistVC = self.storyboard?.instantiateViewControllerWithIdentifier("artistviewstoryboard") as! ArtistViewController
            artistVC.musicViewController = self
            artistVC.theArtist = artistsSorted[indexToBePlayed]
            
            self.showViewController(artistVC, sender: self)
        }
        else if pageIndex == 2 {
            isSeekingPlayerState = false
            let indexToBePlayed = findIndexToBePlayed(albumsByFirstAlphabet, section: indexPath.section, currentRow: indexPath.row)
            
            let albumVC = self.storyboard?.instantiateViewControllerWithIdentifier("albumviewstoryboard") as! AlbumViewController
            albumVC.musicViewController = self
            albumVC.theAlbum = albumsSorted[indexToBePlayed]
            
            self.showViewController(albumVC, sender: self)
        }
        self.musicTable.deselectRowAtIndexPath(indexPath, animated: true)
    }
  
    // MARK: called from SongViewController action sheets
    func goToArtist(theArtist: String) {
        self.view.alpha = 1
        for artist in MusicManager.sharedInstance.uniqueArtists {
            if theArtist == artist.getArtist() {
            
                let artistVC = self.storyboard?.instantiateViewControllerWithIdentifier("artistviewstoryboard") as! ArtistViewController
                artistVC.musicViewController = self
                artistVC.theArtist = artist
                self.navigationController?.popToRootViewControllerAnimated(false)
                self.showViewController(artistVC, sender: self)
                break
            }
        }
    }
    
    func goToAlbum(theAlbum: String) {
        self.view.alpha = 1
        for album in MusicManager.sharedInstance.uniqueAlbums {
            if theAlbum == album.getAlbumTitle() {
                let albumVC = self.storyboard?.instantiateViewControllerWithIdentifier("albumviewstoryboard") as! AlbumViewController
                albumVC.musicViewController = self
                albumVC.theAlbum = album
                self.navigationController?.popToRootViewControllerAnimated(false)
                self.showViewController(albumVC, sender: self)
                break
            }
        }
    }
    
    // MARK: functions using generics to sort the array into sections sorted by first alphabet
    let characters = ["a","b","c","d","e","f","g","h","i","j","k","l","m","n","o","p","q","r","s","t","u","v","w","x","y","z"]
    
    func sort<T: Sortable >(collection: [T]) -> [(String,[T])] {
        var itemsDictionary = [String: [T]]()
        for item in collection {
            var firstAlphabet = item.getSortableName()[0..<1] //get first letter
            var isLetter = false
            //We put every non-alphabet items into a section called "#"
            for character in characters {
                if firstAlphabet.lowercaseString == character {
                    isLetter = true
                    break
                }
            }
            if !isLetter {
                firstAlphabet = "#"
            } else {
                firstAlphabet = firstAlphabet.uppercaseString
            }
            
            if itemsDictionary[firstAlphabet] == nil {
                itemsDictionary[firstAlphabet] = []
            }
            itemsDictionary[firstAlphabet]?.append(item)
        }
        return itemsDictionary.sort{
            (left, right) in
            if left.0 == "#" { //put # at last
                return false
            } else if right.0 == "#" {
                return true
            }
            return left.0 < right.0
        }
    }
    
    
    // For songs, because we need to use the whole collection for the player queue instead an alphabet section, 
    // but indexPath.section and indexPath.row is only return the index of the alphabet section, so to find the
    // actual index in the entire collection, we need to iterate items in previous sections and aggregate together
    func findIndexToBePlayed<T: Sortable> (collectionTuples: [(String, [T])], section: Int, currentRow: Int) -> Int{
        var itemsInPreviousSections = 0
        if section > 0 {
            for i in 1...section {
                itemsInPreviousSections += collectionTuples[i-1].1.count
            }
        }
        return itemsInPreviousSections + currentRow
    }
    
    
    func loadAPISearchImageToCell(cell: MusicCell, song: Findable, imageSize: SearchAPI.ImageSize) {
        dispatch_async((dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0))) {
            SearchAPI.getBackgroundImageForSong(song.getArtist() + " " + song.getTitle(), imageSize: imageSize, completion: {
                image in
                dispatch_async(dispatch_get_main_queue()) {
                    cell.coverImage.image = image
                    CoreDataManager.saveCoverImage(song, coverImage: image)
                }
            })
        }
    }
}



