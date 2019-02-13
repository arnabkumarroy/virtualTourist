//
//  GCD.swift
//  Virtual Tourist
//
//  Created by Arnab Roy on 2/11/19.
//  Copyright © 2019 RoyInc. All rights reserved.
//

import Foundation

/* when you're performing some sort of asynchronous task, such as downloading photos, you don't want that task to happen on the main thread because that would bog down the UI or cause errors. On the other hand, you always want updates to the UI to happen on the main thread, and in fact sometimes iOS will throw and exception if it's not! So the function that you have posted will perform another function on the main thread. The function to perform on the main thread is passed in as a parameter. You would call the performUIUpdatesOnMain function, for example, in the completion handler of an asynchronous task */

func performUIUpdatesOnMain(_ updates: @escaping () -> Void) {
    DispatchQueue.main.async {
        updates()
    }
}
