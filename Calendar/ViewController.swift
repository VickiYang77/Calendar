//
//  ViewController.swift
//  Calendar
//
//  Created by 金融研發一部-楊雅婷 on 2023/7/7.
//

import UIKit
import EventKit
import EventKitUI

class ViewController: UIViewController {
    var startDate = "202308171800".toDate()
    var endDate = "202308181800".toDate()
    
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
            showEditEventView(eventStore)
//            insertEvent(eventStore)
        case .denied:
            print("vvv_Access denied")
        case .notDetermined:
            // 3 初次請求權限許可
            eventStore.requestAccess(to: .event, completion: { [weak self] (granted, error) in
                guard let self = self else { return }
                if granted && error == nil {
                    DispatchQueue.main.async {
                        self.showEditEventView(eventStore)
                        self.insertEvent(eventStore)
                    }
                } else {
                    print("vvv_Access denied")
                }
            })
        default:
            print("vvv_Case default")
        }
    }
    
    // 顯示行事曆編輯頁
    func showEditEventView(_ eventStore: EKEventStore) {
        let eventController = EKEventEditViewController()
        eventController.eventStore = eventStore
        
        let event = EKEvent(eventStore: eventStore)
        event.startDate = startDate
        event.endDate = endDate//startDate.addingTimeInterval(3600) // 添加一小時的時間
        event.title = "行事曆規格"
        event.notes = "備註"
        let alarm = EKAlarm(relativeOffset: -60 * 5) //事件前5min提醒
        event.addAlarm(alarm)
        
        eventController.event = event
        eventController.editViewDelegate = self
        
        self.present(eventController, animated: true, completion: nil)
    }
    
    // 背景新增行事曆Event
    func insertEvent(_ eventStore: EKEventStore) {
        let event:EKEvent = EKEvent(eventStore: eventStore)
        
        // 設定時間區間
//        startDate = Date().addingTimeInterval(1 * 60 * 60) // 1hr後開始
//        endDate = startDate.addingTimeInterval(2 * 60 * 60) // 持續2hr
        event.title = "行事曆規格"
//        event.startDate = startDate
//        event.endDate = endDate
        
        // 設定全天
//        event.isAllDay = true
//        let date = Date()
//        event.startDate = Calendar.current.startOfDay(for: date)
//        event.endDate = Calendar.current.startOfDay(for: date)
        
        
        // 設定小時
        event.startDate = startDate
        event.endDate = endDate
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

extension ViewController: EKEventEditViewDelegate {
    func eventEditViewController(_ controller: EKEventEditViewController, didCompleteWith action: EKEventEditViewAction) {
        controller.dismiss(animated: true)
    }
}

extension String {
    func toDate() -> Date {
        // 創建一個 DateFormatter 實例
        let dateFormatter = DateFormatter()

        // 設定日期字串的格式
        dateFormatter.dateFormat = "yyyyMMddHHmm"

        // 解析日期字串，轉換成 Date 物件
        if let date = dateFormatter.date(from: self) {
            print("vvv_Converted Date: \(date)")
            return date
        } else {
            print("vvv_Date conversion failed")
            return Date()
        }
    }
}

