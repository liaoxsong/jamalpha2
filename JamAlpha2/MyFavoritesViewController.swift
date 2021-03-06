//
//  MyFavoritesViewController.swift
//  JamAlpha2
//
//  Created by Jun Zhou on 12/11/15.
//  Copyright © 2015 Song Liao. All rights reserved.
//

import UIKit
import MediaPlayer

class MyFavoritesViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var tableView: UITableView!
    var isSeekingPlayerState = false
    
    var songs = [SearchResult]()
    var animator: CustomTransitionAnimation?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        loadData()
        createTransitionAnimation()
        setUpNavigationBar()
    }
  

    func createTransitionAnimation(){
        if(animator == nil){
            self.animator = CustomTransitionAnimation()
        }
    }

    func loadData() {
        songs = CoreDataManager.getFavorites()
        self.tableView.reloadData()
    }
    
    func setUpNavigationBar() {
        self.navigationController?.navigationBar.barStyle = UIBarStyle.Black
        self.navigationController?.navigationBar.barTintColor = UIColor.mainPinkColor()
        self.navigationController?.navigationBar.translucent = false
        self.navigationItem.title = "My Favorites"
    }

    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return songs.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("MyFavoritesCell", forIndexPath: indexPath) as! MyFavoritesCell
        let song = songs[indexPath.row]
        cell.numberLabel.text = "\(indexPath.row+1)"
        cell.titleLabel.text = song.getTitle()
        cell.subtitleLabel.text = song.getArtist()
        
        cell.spinner.hidden = true
        return cell
    }
    

    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        isSeekingPlayerState = true
        let song = songs[indexPath.row]
        
        let songVC = self.storyboard?.instantiateViewControllerWithIdentifier("songviewcontroller") as! SongViewController
        
        songVC.selectedFromTable = true
        
        if let item = song.mediaItem {
            MusicManager.sharedInstance.setPlayerQueue([item])
            MusicManager.sharedInstance.setIndexInTheQueue(0)
            MusicManager.sharedInstance.avPlayer.pause()
            MusicManager.sharedInstance.avPlayer.seekToTime(kCMTimeZero)
            MusicManager.sharedInstance.avPlayer.removeAllItems()
            
            if(item.cloudItem && NetworkManager.sharedInstance.reachability.isReachableViaWWAN() ){
                dispatch_async((dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0))) {
                    while (self.isSeekingPlayerState){
                        
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
                                    songVC.parentController = self
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
            }else if (NetworkManager.sharedInstance.reachability.isReachableViaWiFi() || !item.cloudItem){
                isSeekingPlayerState = false
                if(MusicManager.sharedInstance.player.nowPlayingItem == nil){
                    MusicManager.sharedInstance.player.play()
                }
                songVC.selectedFromTable = true
                songVC.parentController = self
                songVC.transitioningDelegate = self.animator
                self.animator!.attachToViewController(songVC)
                self.presentViewController(songVC, animated: true, completion: {
                    completed in
                    //reload table to show loudspeaker icon on current selected row
                    tableView.reloadData()
                })
            } else if ( !NetworkManager.sharedInstance.reachability.isReachable() && item.cloudItem) {
                isSeekingPlayerState = false
                MusicManager.sharedInstance.player.stop()
                KGLOBAL_nowView.stop()
              KGLOBAL_nowView_topSong.stop()
                self.showConnectInternet(tableView)
            }
        }   else if song.getArtist() == "Alex Lisell" { //if demo song
            isSeekingPlayerState = false
            MusicManager.sharedInstance.setDemoSongQueue(MusicManager.sharedInstance.demoSongs, selectedIndex: 0)
            songVC.selectedRow = 0
            songVC.parentController = self
            MusicManager.sharedInstance.player.pause()
            MusicManager.sharedInstance.player.currentPlaybackTime = 0
            songVC.isDemoSong = true
            
            songVC.transitioningDelegate = self.animator
            self.animator!.attachToViewController(songVC)
            
            self.presentViewController(songVC, animated: true, completion: nil)
            
            self.tableView.deselectRowAtIndexPath(indexPath, animated: true)
            
            
        } else { //if the mediaItem is not found, and an searchResult is MyFavoritesCell
            let cell = tableView.cellForRowAtIndexPath(indexPath) as! MyFavoritesCell
            cell.spinner.hidden = false
            cell.spinner.startAnimating()
            isSeekingPlayerState = false
            song.findSearchResult( {
                result in
                
                cell.spinner.stopAnimating()
                cell.spinner.hidden = true
        
                guard let song = result else {
                    
                    self.showMessage("Ooops.. we can't find this song in iTunes.", message: "", actionTitle: "OK", completion: nil)
                    return
                }
                
                songVC.isSongNeedPurchase = true
                songVC.songNeedPurchase = song
                songVC.parentController = self
                songVC.reloadBackgroundImageAfterSearch(song)
                songVC.transitioningDelegate = self.animator
                self.animator!.attachToViewController(songVC)
                self.presentViewController(songVC, animated: true, completion: nil)
                self.tableView.deselectRowAtIndexPath(indexPath, animated: true)
                
            })
        }

    }
}