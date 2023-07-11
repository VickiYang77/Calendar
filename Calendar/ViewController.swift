//
//  ViewController.swift
//  Calendar
//
//  Created by 金融研發一部-楊雅婷 on 2023/7/7.
//

import UIKit
import EventKit

class ViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }
    
    @IBAction func AddEventBtn(_ sender: Any) {
        // 1 初始化
        let eventStore = EKEventStore()
        
        // 2 請求許可權
        switch EKEventStore.authorizationStatus(for: .event) {
        case .authorized:
            insertEvent(eventStore: eventStore)
        case .denied:
            print("vvv_Access denied")
        case .notDetermined:
            // 3 初次請求權限許可
            eventStore.requestAccess(to: .event, completion: { [weak self] (granted, error) in
                guard let self = self else { return }
                if granted && error == nil {
                    self.insertEvent(eventStore: eventStore)
                } else {
                    print("vvv_Access denied")
                }
            })
        default:
            print("vvv_Case default")
        }
    }
    
    func insertEvent(eventStore: EKEventStore) {
        let event:EKEvent = EKEvent(eventStore: eventStore)
        
        // 設定時間區間
        let startDate = Date().addingTimeInterval(1 * 60 * 60) // 1hr後開始
        let endDate = startDate.addingTimeInterval(2 * 60 * 60) // 持續2hr
        event.title = "Test"
//        event.startDate = startDate
//        event.endDate = endDate
        
        // 設定全天
        event.isAllDay = true
        let date = Date()
        event.startDate = Calendar.current.startOfDay(for: date)
        event.endDate = Calendar.current.startOfDay(for: date)
        
        event.notes = "This is a note"
        event.calendar = eventStore.defaultCalendarForNewEvents
        
        // 提醒時間
        let alarm = EKAlarm(relativeOffset: -60 * 10) //事件前10min提醒
        event.addAlarm(alarm)
        
        do {
            try eventStore.save(event, span: .thisEvent)
            
            /*
            DispatchQueue.main.async {
                let alert = UIAlertController(title: "提醒", message: "日曆事件已添加，將在1小時後提醒您！", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "確定", style: .default, handler: nil))
                self.present(alert, animated: true)
            }
             */
        } catch let error as NSError {
            print("vvv_failed to save event with error : \(error)")
        }
        print("vvv_Saved Event")
    }
}

