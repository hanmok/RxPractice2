import UIKit
import RxSwift

func example(of title: String, closure: () -> Void) {
    print("-------------  example of \(title)  -------------")
    closure()
}


//Observables are a fundamental part of RxSwift, but they’re essentially read-only. You may only subscribe to them to get notified of new events they produce.



//A common need when developing apps is to manually add new values onto an observable during runtime to emit to subscribers. What you want is something that can act as both an observable and as an observer. That something is called a Subject.



//like a newspaper publisher, it will receive information and then publish it to subscribers. It’s of type String, so it can only receive and publish strings. After being initialized, it’s ready to receive strings.

example(of: "PublishSubject") {

  let subject = PublishSubject<String>()

//    subject.on(.next("Is anyone listening?"))
    subject.onNext("hi")


    let subscriptionOne = subject
      .subscribe(onNext: { string in
        print(string)
      })

//    PublishSubject only emits to *current* subscribers.

//    So if you weren’t subscribed to it when an event was added to it,
//    you won’t get it when you do subscribe.

//    Now, because subject has a subscriber, it will emit the added value:

    // shortcut for .on(.next("")) -> .onNext("")
    
    subject.onNext("1")
    subject.onNext("2")

}


//MARK: - What are subjects?



// Subjects act as both an observable and an observer.

// You saw earlier how they can receive events and also be subscribed to.



// There are four subject types in RxSwift



// PublishSubject: :Starts empty and only emits new elements to subscribers.

// BehaviorSubject: Starts with an initial value and replays it or the latest element to new subscribers.

// ReplaySubject: Initialized with a buffer size and will maintain a buffer of elements up to that size and replay it to new subscribers.

//AsyncSubject: Emits only the last 'next' event in the sequence, and only when the subject receives a 'completed' event.

// This is a seldom used kind of subject, and you won't use it in this book.





// RxSwift also provides a concept called Relays. RxSwift provides two of these, named PublishRelay and BehaviorRelay. These wrap their respective subjects, but only accept and relay next events.
// You cannot add a completed or error event onto relays at all, so they’re great for non-terminating sequences.

// publishRelay : wrapper for publishSubject
// behaviorRelay : wrapper for behaviorSubject


//MARK: - Working with Publish Subjects
 
//Publish subjects come in handy when you simply want subscribers to be notified of new events from the point at which they subscribed,
// until either they unsubscribe, or
// the subject has terminated with a completed or error event.



//Behavior subject

// Behavior subjects work similarly to publish subjects, except they will replay the latest 'next' event to new subscribers.

// ReplaySubject
// A variant of Subject that 'replays' or emits old values to new subscribers. It buffers a set number of values and will emit those values immediately to any new subscribers in addition to emitting new values to existing subscribers.
