//
//  ViewController.swift
//  Calendar
//
//  Created by Vicki Yang on 2023/7/7.
//

import UIKit
import EventKit
import EventKitUI

class ViewController: UIViewController {
    let eventManager = CalendarManager()
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    @IBAction func ShowEditViewBtn(_ sender: Any) {
        eventManager.sendCalendarEvent(self, title: "edit Event", startTime: "", endTime: "202308261400", notes: "備註欄", alarmTime: 77)
    }
    
    @IBAction func AddEventBtn(_ sender: Any) {
        eventManager.sendCalendarEvent(self, title: "add Event", startTime: "202308220700", endTime: "202308221400", notes: "備註欄", alarmTime: 8, isShowEditView: false) { result in
            switch result {
            case .success():
                let alert = UIAlertController(title: "提醒", message: "行事曆事件已添加！", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "確定", style: .default, handler: nil))
                self.present(alert, animated: true)
            case .failure(let error):
                print("Error：\(error.localizedDescription)")
            }
        }
    }
    
}

extension ViewController: EKEventEditViewDelegate {
    func eventEditViewController(_ controller: EKEventEditViewController, didCompleteWith action: EKEventEditViewAction) {
        controller.dismiss(animated: true)
    }
}

// MARK: - CalendarManager

struct CalendarEvent {
    let title: String
    let startTime: String
    let endTime: String
    let notes: String
    let alarmTime: Double?
    
    var startDate: Date? {
        return startTime.yyyyMMddHHmmToDate()
    }
    
    var endDate: Date? {
        return endTime.yyyyMMddHHmmToDate()
    }
}

class CalendarManager {
    func sendCalendarEvent(_ sourceVC: UIViewController, title: String = "", startTime: String = "", endTime: String = "", notes: String = "", alarmTime: Double? = nil, isShowEditView: Bool = true, completion: ((Result<Void, Error>) -> Void)? = nil) {
        let calendarEvent = CalendarEvent(title: title, startTime: startTime, endTime: endTime, notes: notes, alarmTime: alarmTime)
        
        if !self.checkFormat(sourceVC, calendarEvent: calendarEvent) {
            self.showAlert(sourceVC, message: "STARTIME&ENDTIME格式錯誤")
            return
        }
        
        let eventStore = EKEventStore()
        switch EKEventStore.authorizationStatus(for: .event) {
        case .authorized:
            // 已授權
            self.sendEvent(eventStore, isShowEditView: isShowEditView, calendarEvent: calendarEvent, sourceVC: sourceVC, completion: completion)
        case .denied:
            // 拒絕授權
            let alert = UIAlertController(title: "提醒", message: "請去系統設定開啟行事曆權限！", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "確定", style: .default, handler: nil))
            sourceVC.present(alert, animated: true)
        case .notDetermined:
            // 初次請求權限許可
            eventStore.requestAccess(to: .event, completion: { [weak self] (granted, error) in
                guard let self = self else { return }
                if granted {
                    self.sendEvent(eventStore, isShowEditView: isShowEditView, calendarEvent: calendarEvent, sourceVC: sourceVC, completion: completion)
                } else {
                    print("Calendar Access denied")
                }
            })
        default:
            print("Calendar Case default")
        }
    }
    
    // 資料格式檢查
    private func checkFormat(_ sourceVC: UIViewController, calendarEvent: CalendarEvent) -> Bool {
        var isPass = true
        
        if calendarEvent.startTime.count != 12 || calendarEvent.endTime.count != 12  {
            isPass = false
        } else if calendarEvent.startDate == nil || calendarEvent.endDate == nil {
            isPass = false
        }
        
        return isPass
    }
    
    // 發送行事曆事件
    private func sendEvent(_ eventStore: EKEventStore, isShowEditView: Bool, calendarEvent: CalendarEvent, sourceVC: UIViewController, completion: ((Result<Void, Error>) -> Void)? = nil) {
        DispatchQueue.main.async {
            isShowEditView ? self.showEditView(eventStore, calendarEvent: calendarEvent, sourceVC: sourceVC) : self.insertEvent(eventStore, calendarEvent: calendarEvent, completion: completion)
        }
    }
    
    // 顯示行事曆編輯頁
    private func showEditView(_ eventStore: EKEventStore, calendarEvent: CalendarEvent, sourceVC: UIViewController) {
        let event = createEKEvent(eventStore, calendarEvent: calendarEvent)
        let eventController = EKEventEditViewController()
        eventController.eventStore = eventStore
        eventController.event = event
        eventController.editViewDelegate = sourceVC as? any EKEventEditViewDelegate
        sourceVC.present(eventController, animated: true, completion: nil)
    }
    
    // 背景新增行事曆Event
    private func insertEvent(_ eventStore: EKEventStore, calendarEvent: CalendarEvent, completion: ((Result<Void, Error>) -> Void)? = nil) {
        do {
            let event = createEKEvent(eventStore, calendarEvent: calendarEvent)
            try eventStore.save(event, span: .thisEvent)
            completion?(.success(()))
        } catch let error as NSError {
            completion?(.failure(error))
        }
    }
    
    // 創建event物件 (注意：一定要等用戶允許授權後才可以創建)
    private func createEKEvent(_ eventStore: EKEventStore, calendarEvent: CalendarEvent) -> EKEvent {
        let event = EKEvent(eventStore: eventStore)
        event.title = calendarEvent.title
        event.notes = calendarEvent.notes
        event.calendar = eventStore.defaultCalendarForNewEvents
        
        if let startDate = calendarEvent.startDate, let endDate = calendarEvent.endDate {
            event.startDate = startDate
            event.endDate = endDate
        }
        
        // 事件前幾分鐘提醒
        if let alarmTime = calendarEvent.alarmTime {
            let alarm = EKAlarm(relativeOffset: -60 * alarmTime)
            event.addAlarm(alarm)
        }
        
        return event
    }
    
    private func showAlert(_ sourceVC: UIViewController, message: String = "") {
        DispatchQueue.main.async {
            let alert = UIAlertController(title: "Notify", message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            sourceVC.present(alert, animated: true)
        }
    }
}

extension String {
    func yyyyMMddHHmmToDate() -> Date? {
        return self.toDate(format: "yyyyMMddHHmm")
    }
    
    func toDate(format: String) -> Date? {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = format
        
        if let date = dateFormatter.date(from: self) {
            return date
        } else {
            return nil
        }
    }
}

