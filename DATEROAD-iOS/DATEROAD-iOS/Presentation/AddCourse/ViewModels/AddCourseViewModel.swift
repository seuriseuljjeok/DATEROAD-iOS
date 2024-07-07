//
//  AddCourseViewModel.swift
//  DATEROAD-iOS
//
//  Created by 박신영 on 7/5/24.
//

import UIKit

final class AddCourseViewModel {
   
   var dataSource = getSampleImages()
   
   var dateName: ObservablePattern<String> = ObservablePattern("")
   
   var visitDate: ObservablePattern<String> = ObservablePattern("")
   
   var dateStartTime: ObservablePattern<String> = ObservablePattern("")
   
   var tagButtonsArr: [UIButton] = []
   
   var isError: (() -> Void)?
   
   var isNonError: (() -> Void)?
   
}

extension AddCourseViewModel {
   
   func isFutureDate() {
      let dateStr = visitDate.value ?? ""
      let dateFormatter = DateFormatter()
      dateFormatter.dateFormat = "yyyy. MM. dd."
      
      let today = Date()
      let selectedDate = dateFormatter.date(from: dateStr)
      
      let flag = (selectedDate ?? today) > today
      
      flag ? isError?() : isNonError?()
   }
   
}
