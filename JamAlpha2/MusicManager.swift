//
//  MusicManager.swift
//  JamAlpha2
//
//  Created by Song Liao on 8/28/15.
//  Copyright (c) 2015 Song Liao. All rights reserved.
//

import Foundation
import AVFoundation
import MediaPlayer
import UIKit

protocol Sortable {
    func getSortableName()-> String
}

extension MPMediaItem: Sortable {
    func getSortableName() -> String {
        return self.title!
    }
}

class MusicManager: NSObject {
    
    let _TAG = "MusicManager"
    var player: MPMusicPlayerController!
    
    var avPlayer: AVQueuePlayer!
    
    // A queue that keep tracks the last queue to the player
    // this should never be accessed outside MusicManager
    // a current collection is always passed in from function
    // 'setPlayerQueue'
    var lastPlayerQueue = [MPMediaItem]()
    var lastSelectedIndex = -1
    
    var uniqueSongs : [MPMediaItem]!
    var uniqueAlbums = [SimpleAlbum]()
    var uniqueArtists = [SimpleArtist]()
    
    var songsByFirstAlphabet = [(String, [MPMediaItem])]()
    var artistsByFirstAlphabet = [(String, [SimpleArtist])]()
    var albumsByFirstAlphabet = [(String, [SimpleAlbum])]()
    
    var songsSorted : [MPMediaItem]!
    var albumsSorted = [SimpleAlbum]()
    var artistsSorted = [SimpleArtist]()
    
    var demoSongs: [AVPlayerItem]!
    var lastLocalPlayerQueue = [AVPlayerItem]()
    
    //in case mediaItem was changed outside the app when exit to background from Editor screen
    //we save these two so that when we come back we always have the correct item
    var lastPlayingItem: MPMediaItem!
    var lastPlayingTime: NSTimeInterval!

    class var sharedInstance: MusicManager {
        struct Static {
            static var onceToken: dispatch_once_t = 0
            static var instance: MusicManager? = nil
        }
        dispatch_once(&Static.onceToken) {
            Static.instance = MusicManager()
        }
        return Static.instance!
    }
    
    override init() {
        super.init()
        loadCollections()
        initializePlayer()
        addNotification()
    }
    
    //check when search a cloud item, if it matches, we use the song we already have
    func itemFoundInCollection(songToCheck: Findable) -> MPMediaItem? {
        let result = uniqueSongs.filter{
            (item: MPMediaItem) -> Bool in
            return MusicManager.sharedInstance.songsMatched(findableA: songToCheck, findableB: item)
        }.first
        if(result != nil){
            return result!
        }
        return nil
    }
    
    func addNotification(){
       NSNotificationCenter.defaultCenter().addObserver(self, selector: "musicLibraryDidChange", name: MPMediaLibraryDidChangeNotification, object: nil)
        MPMediaLibrary.defaultMediaLibrary().beginGeneratingLibraryChangeNotifications()
    }
    
    
    func musicLibraryDidChange() {
      reloadCollections()
      NSNotificationCenter.defaultCenter().postNotification(NSNotification(name: reloadCollectionsNotificationKey, object: nil))
    }

    func loadCollections() {
        loadLocalSongs()
        loadLocalAlbums()
        loadLocalArtist()
    }
    
    func reloadCollections() {
        loadCollections()
        queueChanged = true
    }
    
    func initializePlayer(){
        //save current playing time and time and reset player after it is being stopped
        var lastPlayingItem: MPMediaItem?
        var lastPlayTime: NSTimeInterval = 0
        var rate:Float = 0
        if let nowPlayingItem = MPMusicPlayerController.systemMusicPlayer().nowPlayingItem {
            lastPlayingItem = nowPlayingItem
            lastPlayTime = MPMusicPlayerController.systemMusicPlayer().currentPlaybackTime
            rate = MPMusicPlayerController.systemMusicPlayer().currentPlaybackRate
        }
        
        MPMusicPlayerController.systemMusicPlayer().nowPlayingItem = nil
        player = MPMusicPlayerController.systemMusicPlayer()
        player.repeatMode = .All
        player.shuffleMode = .Off
        
        if let lastItem = lastPlayingItem {
            self.setPlayerQueue([lastPlayingItem!])
            player.nowPlayingItem = lastItem
            player.currentPlaybackTime = lastPlayTime + 0.32
            player.prepareToPlay()
            
            if rate > 0 {
                player.currentPlaybackRate = rate
            }else{
                player.pause()
            }
        }else{
            self.setPlayerQueue(uniqueSongs)
        }
        
        //initialize AVQueuePlayer
        self.avPlayer = AVQueuePlayer()
        self.avPlayer.actionAtItemEnd = .None
        self.setSessionActiveWithMixing()
    }
    
    //for playing mode and background mode
    private func setSessionActiveWithMixing() {
        do {
            //set option DefaultToSpeaker so that demo song will not lag while soundwave is generating in the background
            try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback, withOptions: .DefaultToSpeaker)
        } catch _ {
        }
        
        do {
            try AVAudioSession.sharedInstance().setActive(true)
        } catch _ {
        }
    }
    
    private var queueChanged = false
    
    func setDemoSongQueue(collection: [AVPlayerItem], selectedIndex:Int){
        if(avPlayer.currentItem == nil || avPlayer.currentItem != collection[selectedIndex]){
            avPlayer.removeAllItems()
            avPlayer.insertItem(collection[selectedIndex], afterItem: nil)
        }
    }

    func setPlayerQueue(collection: [MPMediaItem]){
        //for iOS 8.1 devices, MPMediaItemCollectionInitException causes a crash if no music found
        if collection.isEmpty {
            return
        }
        if lastPlayerQueue == collection { // if we are the same queue
            queueChanged = false
        } else { //if different queue, means we are getting a new collection, reset the player queue
            player.setQueueWithItemCollection(MPMediaItemCollection(items: collection))
            lastPlayerQueue = collection
            queueChanged = true
            return
        }
        
        // after come back from music app which the current playing item is set to nil, we set the collection
        if(!queueChanged && player.nowPlayingItem == nil){
            player.setQueueWithItemCollection(MPMediaItemCollection(items: collection))
            lastPlayerQueue = collection
            queueChanged = true
            KGLOBAL_isNeedToCheckIndex = false
            return
        }
        
        //coming from music app to twistjam, if the queue is different, we reset the queue to newly selected queue

        if KGLOBAL_isNeedToCheckIndex {

            let repeatMode = player.repeatMode
            let shuffleMode = player.shuffleMode
            player.repeatMode = .All
            player.shuffleMode = .Off
            if (player.nowPlayingItem == nil) || (lastPlayerQueue.indexOf(player.nowPlayingItem!) != nil ? Int(lastPlayerQueue.indexOf(player.nowPlayingItem!)!) : -1) != player.indexOfNowPlayingItem {
                player.setQueueWithItemCollection(MPMediaItemCollection(items: collection))
                lastPlayerQueue = collection
                queueChanged = true
            }
            KGLOBAL_isNeedToCheckIndex = false
            player.repeatMode = repeatMode
            player.shuffleMode = shuffleMode
        }
    }
    
    func setIndexInTheQueue(selectedIndex: Int){
        // 如果单曲循环的话 切出去 再换一首歌的话 还是之前那个首歌
        if player.repeatMode == .One && player.shuffleMode == .Off {
            player.repeatMode = .All  //暂时让他变成列表循环
            if player.nowPlayingItem != lastPlayerQueue[selectedIndex] || player.nowPlayingItem == nil {
                player.nowPlayingItem = lastPlayerQueue[selectedIndex]
            }
            player.repeatMode = .One
        } else { // for other repeat mode
            
            // if current playing song is not what we selected from the table
            if player.nowPlayingItem != lastPlayerQueue[selectedIndex] || player.nowPlayingItem == nil {
                player.prepareToPlay()
                player.nowPlayingItem = lastPlayerQueue[selectedIndex]
                
            } else {
                if queueChanged { // if we selected the same song from a different queue this time
                    let lastPlaybackTime = player.currentPlaybackTime
                    player.prepareToPlay() // set current playing index to zero
                    player.nowPlayingItem = lastPlayerQueue[selectedIndex] // this has a really short time lag
                    player.currentPlaybackTime = lastPlaybackTime + 0.32
                }
            }
        }
        lastSelectedIndex = selectedIndex
    }
    
    // MARK: get all MPMediaItems
    func loadLocalSongs() {
        uniqueSongs = [MPMediaItem]()
        let songCollection = MPMediaQuery.songsQuery()
        uniqueSongs = songCollection.items!
        songsByFirstAlphabet = sort(uniqueSongs)
        songsSorted = getAllSortedItems(songsByFirstAlphabet)
        
        loadDemoSongs()
    }
    
    func loadDemoSongs() {
        //we have one demo song so far
        demoSongs = kSongNames.map {
            AVPlayerItem(URL: NSBundle.mainBundle().URLForResource($0, withExtension: "mp3")!)
        }
    }
    
    func loadLocalAlbums(){
        uniqueAlbums = [SimpleAlbum]()

        let albumQuery = MPMediaQuery.albumsQuery()
        let allAlbumsCollections = albumQuery.collections
        
        for collection in allAlbumsCollections! {
            let album = SimpleAlbum(collection: collection)
            uniqueAlbums.append(album)
        }
        
        albumsByFirstAlphabet = sort(uniqueAlbums)
        albumsSorted = getAllSortedItems(albumsByFirstAlphabet)
    }
    
    //load artist must be called after getting all albums
    func loadLocalArtist() {
        uniqueArtists = [SimpleArtist]()
    
        let artistQuery = MPMediaQuery.artistsQuery()
        let allAlbumsCollections = artistQuery.collections
        
        for collection in allAlbumsCollections! {
            let artist = SimpleArtist(collection: collection)
            uniqueArtists.append(artist)
        }
        
        artistsByFirstAlphabet = sort(uniqueArtists)
        artistsSorted = getAllSortedItems(artistsByFirstAlphabet)
    }

    let characters = ["A","B","C","D","E","F","G","H","I","J","K","L","M","N","O","P","Q","R","S","T","U","V","W","X","Y","Z"]
    
    
    func sort<T: Sortable >(collection: [T]) -> [(String,[T])] {
     
        var itemsDictionary = [String: [T]]()
        for item in collection {
            var firstAlphabet = item.getSortableName()[0..<1].uppercaseString //get first letter
            firstAlphabet = characters.indexOf(firstAlphabet) == nil ? "#" : firstAlphabet
            
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
    
    // Used in didSelectForRow
    // return sorted items in a single array
    func getAllSortedItems<T: Sortable> (collectionTuples: [(String, [T])]) -> [T] {
        var allItemsSorted = [T]()
        for itemSectionByAlphabet in collectionTuples {
            for item in itemSectionByAlphabet.1 {
                allItemsSorted.append(item)
            }
        }
        return allItemsSorted
    }
    
    // we manually set the repeat mode to one before going to tabs or lyrics Editor
    // we save the shuffle, repeat, currentPlaying time state so that when we come back from editors we can resume correctly
    func saveMusicPlayerState(collection: [MPMediaItem]) -> (MPMusicRepeatMode, MPMusicShuffleMode, NSTimeInterval) {
        let previousRepeatMode: MPMusicRepeatMode = player.repeatMode
        let previousShuffleMode: MPMusicShuffleMode = player.shuffleMode
        let previousPlayingTime: NSTimeInterval = player.currentPlaybackTime
        player.repeatMode = .One
        player.shuffleMode = .Off
        player.currentPlaybackTime = 0
        
        return (previousRepeatMode, previousShuffleMode, previousPlayingTime)
    }
    
    // back to song view controller recover queue
    func recoverMusicPlayerState(sender: (MPMusicRepeatMode, MPMusicShuffleMode, NSTimeInterval), currentSong: MPMediaItem) {
        player.repeatMode = sender.0
        player.shuffleMode = sender.1
        player.currentPlaybackTime = sender.2
    }
    
    func songsMatched(findableA findableA: Findable, findableB: Findable) -> Bool {
        if findableA.getTitle().lowercaseString == findableB.getTitle().lowercaseString &&
        findableA.getArtist().lowercaseString == findableB.getArtist().lowercaseString &&
            abs(findableA.getDuration() - findableB.getDuration()) < 2 {
                return true
        }
        return false
    }
}