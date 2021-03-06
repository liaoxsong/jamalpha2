//
//  coreData.swift
//  tabEditorV3
//
//  Created by Jun Zhou on 9/2/15.
//  Copyright (c) 2015 Jun Zhou. All rights reserved.
//

import Foundation
import CoreData

class TabsDataManager: NSObject {
    
    static let moc: NSManagedObjectContext = SwiftCoreDataHelper.managedObjectContext()
    
    static let fretsBoard: [[String]] = [
        //Fret board note, from high E string to low E string
        ["E", "F", "F#", "G", "G#", "A", "A#", "B", "C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B", "C", "C#", "D", "D#", "E"],
        ["B", "C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B", "C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"],
        ["G", "G#", "A", "A#", "B", "C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B", "C", "C#", "D", "D#", "E", "F", "F#", "G"],
        ["D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B", "C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B", "C", "C#", "D"],
        ["A", "A#", "B", "C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B", "C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A"],
        ["E", "F", "F#", "G", "G#", "A", "A#", "B", "C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B", "C", "C#", "D", "D#", "E"]
    ]

    class func commonChords() -> [String: String] {
        var commonChords: [String: String] = [String: String]()
        //4th string
        commonChords["40000"] = "xxxx00020302"//D
        commonChords["40001"] = "xxxx00020301"
        commonChords["40002"] = "xxxx00020102"
        commonChords["40003"] = "xxxx00020101"
        commonChords["40300"] = "xxxx03020101"//F
        //5th string
        for i in 0..<4 {
            for j in 0..<23 {
                if i == 0 { // major chords, e,g, A major -> xx 00 22 22 22 00
                    if j == 3 {
                        commonChords["50300"] = "xx0302000100"
                    } else {
                        if j < 8 {
                            //xx0204040404
                            commonChords["\(500 + j)00"] = "xx0\(j)0\(j + 2)0\(j + 2)0\(j + 2)0\(j)"
                        } else if j >= 8 && j < 10 {
                            commonChords["\(500 + j)00"] = "xx0\(j)\(j + 2)\(j + 2)\(j + 2)0\(j)"
                        } else {
                            commonChords["\(500 + j)00"] = "xx\(j)\(j + 2)\(j + 2)\(j + 2)\(j)"
                        }
                    }
                } else if i == 1 {
                    if j < 8 { //minor chords, Bm -> xx 02 04 04 03 00
                        commonChords["\(500 + j)01"] = "xx0\(j)0\(j + 2)0\(j + 2)0\(j + 1)0\(j)"
                    } else if j == 8 {
                        commonChords["\(500 + j)01"] = "xx0\(j)\(j + 2)\(j + 2)0\(j + 1)0\(j)"
                    } else if j == 9 {
                        commonChords["\(500 + j)01"] = "xx0\(j)\(j + 2)\(j + 2)\(j + 1)0\(j)"
                    }else {
                        commonChords["\(500 + j)01"] = "xx\(j)\(j + 2)\(j + 2)\(j + 1)\(j)"
                    }
                } else if i == 2 { //7
                    if j < 8 {
                        commonChords["\(500 + j)02"] = "xx0\(j)0\(j + 2)0\(j)0\(j + 2)0\(j)"
                    } else if j >= 8 && j < 10 {
                        commonChords["\(500 + j)02"] = "xx0\(j)\(j + 2)0\(j)\(j + 2)0\(j)"
                    } else {
                        commonChords["\(500 + j)02"] = "xx\(j)\(j + 2)\(j)\(j + 2)\(j)"
                    }
                } else if i == 3 { //m7
                    if j < 8 {
                        commonChords["\(500 + j)03"] = "xx0\(j)0\(j + 2)0\(j)0\(j + 1)0\(j)"
                    } else if j == 8 {
                        commonChords["\(500 + j)03"] = "xx0\(j)\(j + 2)0\(j)0\(j + 1)0\(j)"
                    } else if j == 9 {
                        commonChords["\(500 + j)03"] = "xx0\(j)\(j + 2)0\(j)\(j + 1)0\(j)"
                    } else {
                        commonChords["\(500 + j)03"] = "xx\(j)\(j + 2)\(j)\(j + 1)\(j)"
                    }
                }
            }
        }
        
        //6th string
        for i in 0..<3 {
            for j in 0..<23 {
                if i == 0 {
                    if j == 3 {
                        commonChords["60300"] = "030200000003"
                    } else {
                        if j < 8 {
                            commonChords["\(600 + j)00"] = "0\(j)0\(j + 2)0\(j + 2)0\(j + 1)0\(j)0\(j)"
                        } else if j == 8 {
                            commonChords["\(600 + j)00"] = "0\(j)\(j + 2)\(j + 2)0\(j + 1)0\(j)0\(j)"
                        } else if j == 9 {
                            commonChords["\(600 + j)00"] = "0\(j)\(j + 2)\(j + 2)\(j + 1)0\(j)0\(j)"
                        }else {
                            commonChords["\(600 + j)00"] = "\(j)\(j + 2)\(j + 2)\(j + 1)\(j)\(j)"
                        }
                    }
                } else if i == 1 {
                    if j < 8 {
                        commonChords["\(600 + j)01"] = "0\(j)0\(j + 2)0\(j + 2)0\(j)0\(j)0\(j)"
                    } else if j >= 8 && j < 10 {
                        commonChords["\(600 + j)01"] = "0\(j)\(j + 2)\(j + 2)0\(j)0\(j)0\(j)"
                    } else {
                        commonChords["\(600 + j)01"] = "\(j)\(j + 2)\(j + 2)\(j)\(j)\(j)"
                    }
                } else if i == 2 {
                    if j == 3 {
                        commonChords["60302"] = "03xx00000001"
                    }
                    if j < 8 {
                        commonChords["\(600 + j)02"] = "0\(j)0\(j + 2)0\(j)0\(j + 1)0\(j)0\(j)"
                    } else if j == 8 {
                        commonChords["\(600 + j)02"] = "0\(j)\(j + 2)0\(j)0\(j + 1)0\(j)0\(j)"
                    } else if j == 9 {
                        commonChords["\(600 + j)02"] = "0\(j)\(j + 2)0\(j)\(j + 1)0\(j)0\(j)"
                    }else {
                        commonChords["\(600 + j)02"] = "\(j)\(j + 2)\(j)\(j + 1)\(j)\(j)"
                    }
                }
            }
        }
        commonChords["60003"] = "000202000300"
        return commonChords
    }
    
    class func addDefaultData() {
        let results: NSArray = SwiftCoreDataHelper.fetchEntities(NSStringFromClass(Tabs), withPredicate: nil, managedObjectContext: moc)
        if results.count < 1 { // if results are empty, we initiate original tabs
            let dict = commonChords()
            for i in 4..<7 { //chord starts at 4th string
                for j in 0..<25 {
                    let index = NSNumber(integer: i * 10000 + j * 100)
                    let note = fretsBoard[i - 1][j]
                    insertInitialTabs(index, name: note, dict: dict)
                }
            }
        }
    }
    
    
    class func insertInitialTabs(index: NSNumber, name: String, dict: Dictionary<String, String>) {
    var tabSuffix: [String] = ["", "m", "7", "m7"]

    for i in 0..<4 {
        let temp = "\(Int(index) + i)"
        if dict[temp] != nil {
            let tab: Tabs = SwiftCoreDataHelper.insertManagedObject(NSStringFromClass(Tabs), managedObjectConect: moc) as! Tabs
            let noteName = "\(name)\(tabSuffix[i])"
            tab.name = noteName
            let tempIndex = Int(index) / 100
            tab.isOriginal = true
            tab.index = NSNumber(integer: tempIndex)
            tab.content = dict[temp]!
        }
    }
        SwiftCoreDataHelper.saveManagedObjectContext(moc)
    }
    
    // get all tabs give a fret positino
    class func getTabsSets(index: NSNumber) -> [NormalTabs] {
        var tempTabSet: [NormalTabs] = [NormalTabs]()
        let fetchRequest = NSFetchRequest(entityName: "Tabs")
        fetchRequest.predicate = NSPredicate(format: "index == '\(index)'")
        do {
            if let results = try moc.executeFetchRequest(fetchRequest) as? [Tabs] {
                for item in results {
                    
                    let tempItem: Tabs = item as Tabs
                    let tempTab: NormalTabs = NormalTabs()
                    tempTab.name = tempItem.name
                    tempTab.index = tempItem.index
                    tempTab.content = tempItem.content
                    tempTab.isOriginal = tempItem.isOriginal
                    tempTab.tabs = tempItem
                    tempTabSet.append(tempTab)
                }
                return sortTabsSets(tempTabSet)
            }
        } catch {
            fatalError("There was an error fetching tabs on the index \(index)")
        }
        return [NormalTabs]()
    }
    
    // get tabs by index, name and content
    class func getUniqueTab(index: NSNumber, name: String, content: String) -> NormalTabs? {
        var tempNormalTabs: NormalTabs!
        let fetchRequest = NSFetchRequest(entityName: "Tabs")
        fetchRequest.predicate = NSPredicate(format: "index == '\(index)' AND name == '\(name)' AND content == '\(content)'")
        do {
            if let results = try moc.executeFetchRequest(fetchRequest) as? [Tabs] {
                for item in results {
                    let tempItem: Tabs = item as Tabs
                    let tempTab: NormalTabs = NormalTabs()
                    tempTab.name = tempItem.name
                    tempTab.index = tempItem.index
                    tempTab.content = tempItem.content
                    tempTab.isOriginal = tempItem.isOriginal
                    tempTab.tabs = tempItem
                    tempNormalTabs = tempTab
                }
                return tempNormalTabs
            }
        } catch {
            fatalError("There was an error fetching tabs on the index \(index)")
        }
        return nil
    }
    
    class func addNewTabs(index: NSNumber, name: String, content: String) -> Tabs {
        let tabs: Tabs = SwiftCoreDataHelper.insertManagedObject(NSStringFromClass(Tabs), managedObjectConect: moc) as! Tabs
        tabs.index = index
        tabs.name = name
        tabs.content = content
        tabs.isOriginal = false
        SwiftCoreDataHelper.saveManagedObjectContext(moc)
        return tabs
    }
    

    class func removeTabs(tabs: Tabs) {
        if tabs.isOriginal {
            return
        }
        moc.deleteObject(tabs)
        SwiftCoreDataHelper.saveManagedObjectContext(moc)
    }

    class func printAllNewTabs() {
        let fetchRequest = NSFetchRequest(entityName: "Tabs")
        fetchRequest.predicate = NSPredicate(format: "isOriginal == false")//needs to verify this works
        do {
            if let results = try moc.executeFetchRequest(fetchRequest) as? [Tabs] {
                for result in results {
                    print("\(result.index) + \(result.name) + \(result.content)")
                }
            }
        } catch {
            fatalError("There was an error fetching all new tabs")
        }
    }
    
    //Sort tab sets given on a index to the order of major, minor, m7, 7, and user added ones
    class func sortTabsSets(tabsSets: [NormalTabs]) -> [NormalTabs] {
        return tabsSets.sort{
            (left, right) in
            if !left.isOriginal { // put all non-original last unsorted, maybe later by uses frequency
                return false
            } else if !right.isOriginal {
                return true
            }
            // everything now on are original chords
            if left.name.characters.count == 1 { // put major chord first
                return true
            } else if right.name.characters.count == 1 {
                return false
            }
            
            //put minor chords second
            let lastLeftCharacter = Array(left.name.characters)[left.name.characters.count-1]
            let lastRightCharacter = Array(right.name.characters)[right.name.characters.count-1]
            if lastLeftCharacter == "m" {
                return true
            } else if lastRightCharacter == "m" {
                return false
            }
            //put minor 7 at 3rd place
            if left.name.characters.count == 3 { //then we put m7 chord at last of original
                return true
            } else if right.name.characters.count == 3 {
                return false
            }
            //put 7 chord at last of the 4
            return false
        }

    }
}