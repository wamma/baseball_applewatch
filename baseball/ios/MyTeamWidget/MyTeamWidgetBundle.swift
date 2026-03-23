//
//  MyTeamWidgetBundle.swift
//  MyTeamWidget
//
//  Created by hyung jun on 3/20/26.
//

import WidgetKit
import SwiftUI

@main
struct MyTeamWidgetBundle: WidgetBundle {
    var body: some Widget {
        MyTeamWidget()
        MyTeamWidgetControl()
        MyTeamWidgetLiveActivity()
    }
}
