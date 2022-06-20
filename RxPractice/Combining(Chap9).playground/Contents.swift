import UIKit
import RxSwift

var greeting = "Hello, playground"

func example(of title: String, closure: () -> Void) {
    print("---------- \(title) ----------")
    closure()
}


//RxSwift is all about working with and mastering asynchronous sequences. But you’ll often need to make order out of chaos! There is a lot you can accomplish by combining observables.

// MARK: - Prefixing and concatenating

//The first and most obvious need when working with observables is to guarantee that an observer receives an initial value.
//There are situations where you’ll need the “current state” first. Good use cases for this are “current location” and “network connectivity status.” These are some observables you’ll want to prefix with the current state.

example(of: "startWith") {
    let numbers = Observable.of(2,3,4)
    
//    Create a sequence starting with the value 1, then continue with the original sequence of numbers.
    let observable = numbers.startWith(1)
    _ = observable.subscribe(onNext: { value in
        print(value)
    })
//Note: We purposely don‘t keep the Disposable returned by the subscription, because the Observable here immediately completes after emitting its two items. Therefore, our subscription will automatically end. You will use this form in further examples when it‘s safe to do so.
}

//The startWith(_:) operator prefixes an observable sequence with the given initial value. This value must be of the same type as the observable elements.

//As it turns out, startWith(_:) is the simple variant of the more general concat family of operators. Your initial value is a sequence of one element, to which RxSwift appends the sequence that startWith(_:) chains to. The Observable.concat(_:) static function chains two sequences.

// first : 1 2 3
// second: 4 5 6
// concat: 1 2 3  4 5 6

example(of: "Observable.concat") {
    let first = Observable.of(1, 2, 3)
    let second = Observable.of(4, 5, 6)
    
    let observable = Observable.concat([first, second])
    
    observable.subscribe(onNext: { value in
        print(value)
    })
}

// The Observable.concat(_:) static method takes either an ordered collection of observables (i.e. an array), or a variadic list of observables.
// It subscribes to the first sequence of the collection, relays its elements until it completes, then moves to the next one.
// The process repeats until all the observables in the collection have been used. If at any point an inner observable emits an error, the concatenated observable in turn emits the error and terminates.

example(of: "concat") {
    let germanCities = Observable.of("Berlin", "Münich",
    "Frankfurt")
      let spanishCities = Observable.of("Madrid", "Barcelona",
    "Valencia")
    
    let observable = germanCities.concat(spanishCities)
    _ = observable.subscribe(onNext: { value in
        print(value)
    })
}

// This variant applies to an existing observable. It waits for the source observable to complete, then subscribes to the parameter observable.
// Aside from instantiation, it works just like Observable.concat(_:).


//Note: Observable sequences are strongly typed. You can only concatenate sequences whose elements are of the same type!
//If you try to concatenate sequences of different types, brace yourself for compiler errors. The Swift compiler knows when one sequence is an Observable<String> and the other an Observable<Int> so it will not allow you to mix them.

example(of: "concatMap") {
    let sequences = [
        "German cities": Observable.of("Berlin", "Münich",
    "Frankfurt"),
        "Spanish cities": Observable.of("Madrid", "Barcelona",
    "Valencia")
      ]
    
//    Has a sequence emit country names, each in turn mapping to a sequence emitting city names for this country.
    let observable = Observable.of("German cities", "Spanish cities")
        .concatMap { country in sequences[country] ?? .empty() }
    // Projects each element of an observable sequence to an observable sequence and concatenates the resulting observable sequences into one observable sequence.
    
//    Outputs the full sequence for a given country before starting to consider the next one.
    _ = observable.subscribe(onNext: { string in
        print(string)
    })
}


// MARK: - Merging

//RxSwift offers several ways to combine sequences. The easiest to start with is merge.


example(of: "merge") {
    let left = PublishSubject<String>()
    let right = PublishSubject<String>()
    
//    Next, create a source observable of observables — it’s like Inception! To keep things simple, make it a fixed list of your two subjects:
    let source = Observable.of(left.asObservable(), right.asObservable())
    
    let observable = source.merge()
    _ = observable.subscribe(onNext: { value in
        print(value)
    })
    
//    Then you need to randomly pick and push values to either observable. The loop uses up all values from leftValues and rightValues arrays then exits.
    var leftValues = ["Berlin", "Munich", "Frankfurt"]
    var rightValues = ["Madrid", "Barcelona", "Valencia"]
    
    repeat  {
        switch Bool.random() {
        case true where !leftValues.isEmpty:
            left.onNext("Left: " + leftValues.removeFirst())
        case false where !rightValues.isEmpty:
            right.onNext("Right: " + rightValues.removeFirst())
        default:
            break
        }
    } while !leftValues.isEmpty || !rightValues.isEmpty
                
                left.onCompleted()
                right.onCompleted()
}

// A merge() observable subscribes to each of the sequences it receives and emits the elements as soon as they arrive - there's no predefined order.

// merge() completes after its source sequence completes and all inner sequences have completed.

// The order in which the inner sequences complete is irrelevant.

// If any of the sequences emit an error, the merge() observable imediately relays the error, then terminates.


//Take a second to look at the code. Notice that merge() takes a source observable, which itself emits observables sequences of the element type. This means that you could send a lot of sequences for merge() to subscribe to!


//To limit the number of sequences subscribed to at once, you can use merge(maxConcurrent:). This variant keeps subscribing to incoming sequences until it reaches the maxConcurrent limit. After that, it puts incoming observables in a queue. It will subscribe to them in order, as soon as one of the active sequences completes.


//Note: You might end up using this limiting variant less often than merge() itself. Keep it in mind, though, as it can be handy in resource-intensive situations. You could use it in scenarios such as when making a lot of network requests to limit the number of concurrent outgoing connections.


// MARK: - Combining elements

// An essential group of operators in RxSwift is the combineLatest family. They combine values from several sequences

//                         left   :  1               2            3
//                         right  :     4      5           6
// combineLatest left and right   :     1,4    1,5   2,5   2,6    3,6


// Every time one of the inner (combined) sequences emits a value, it calls a closure you provide. You receive the last value emitted by each of the inner sequences. This has many concrete applications, such as observing several test fields at once and combining their values, watching the status of multiple sources, and so on.


example(of: "combineLatest") {
    let left = PublishSubject<String>()
    let right = PublishSubject<String>()
    
    let observable = Observable.combineLatest(left, right) {
        lastLeft, lastRight in
        "\(lastLeft) \(lastRight)"
    }
    
//    let observable2 = Observable.combineLatest([left, right]) {
//        strings in strings.joined(separator: " ")
//    }
    
    _ = observable.subscribe(onNext: { value in
        print(value)
    })
    
    left.onNext("Hello,")
    
    right.onNext("world") // Hello, World
    
    right.onNext("RxSwift") // Hello, RxSwift
    
    left.onNext("Have a good day,") // Have a good day, RxSwift
    
    left.onCompleted()
    right.onCompleted()
}


//1. You combine observables using a closure receiving the latest value of each sequence as arguments. In this example, the combination is the concatenated string of both left and right values. It could be anything else that you need, as the type of the elements the combined observable emits is the return type of the closure. In practice, this means you can combine sequences of heterogeneous types. It is one of the rare core operators that permit this, the other being withLatestFrom(_:) you‘ll learn about in a short while.

//2. Nothing happens until each of the observables emit one value. After that, each time one emits a new value, the closure receives the latest value of each of the observables and produces its result.


//Like the map(_:) operator covered in Chapter 7, “Transforming Operators,” combineLatest(_:_:resultSelector:) creates an observable whose type is the closure return type. This is a great opportunity to switch to a new type alongside a chain of operators!

//A common pattern is to combine values to a tuple then pass them down the chain. For example, you’ll often want to combine values and then call filter(_:) on them like so:

example(of: "combineLatest2") {
    let left = PublishSubject<String>()
    let right = PublishSubject<String>()
    
    let observable = Observable
        .combineLatest(left, right) { ($0, $1) }
        .filter { !$0.0.isEmpty }
}


//There are several variants in the combineLatest family of operators. They take between two and eight observable sequences as parameters. As mentioned above, sequences don’t need to have the same element type.


example(of: "combine user choice and value") {
    let choice: Observable<DateFormatter.Style> = Observable.of(.short, .long)
    let dates = Observable.of(Date())
    
    let observable = Observable.combineLatest(choice, dates) { format, when -> String in
        let formatter = DateFormatter()
        formatter.dateStyle = format
        return formatter.string(from: when)
    }
    
    _ = observable.subscribe(onNext: { value in
        print(value)
    })
}

//This example demonstrates automatic updates of on-screen values when the user settings change. Think about all the manual updates you’ll remove with such patterns!


//A final variant of the combineLatest family takes a collection of observables and a combining closure, which receives latest values in an array. Since it’s a collection, all observables carry elements of the same type.

// Since it's less flexible than the multiple parameter variants, it is seldom-used but still handy to know about


//let observable = Observable.combineLatest(left, right) {
//    lastLeft, lastRight in
//    "\(lastLeft) \(lastRight)"
//}

//let observable2 = Observable.combineLatest([left, right]) {
//    strings in strings.joined(separator: " ")
//}


// Note: Last but not least, combineLatest completes only when the last of its inner sequences completes. Before that, it keeps sending combined values. If some sequences terminate, it uses the last value emitted to combine with new values from other sequences.


// Another combination operator is the `zip` family of operators.
// Like the combineLatest family, it comes in several variants:

// left : sunny         cloudy    cloudy    ->
// right:   Lisbon              London          Vienna ->
// zip  :   sunny,Lisbon        cloudy,London   cloudy,Vienna
//(left and right)


example(of: "zip") {
    enum Weather {
        case cloudy
        case sunny
    }
    
    let left: Observable<Weather> = Observable.of(.sunny, .cloudy,
                                                  .cloudy, .sunny)
    let right = Observable.of("Lisbon", "Copenhagen", "London",
                              "Madrid", "Vienna")
    
    let observable = Observable.zip(left, right) { weather, city in
        return "It's \(weather) in \(city)"
    }
    
    _ = observable.subscribe(onNext: { value in
        print(value)
    })
//    It's sunny in Lisbon
//    It's cloudy in Copenhagen
//    It's cloudy in London
//    It's sunny in Madrid

}

//Here’s what zip(_:_:resultSelector:) did for you:
//• Subscribed to the observables you provided.
//• Waited for each to emit a new value.
//• Called your closure with both new values.


//The explanation lies in the way zip operators work. They pair each next value of each observable at the same logical position (1st with 1st, 2nd with 2nd, etc.). This implies that if no next value from one of the inner observables is available at the next logical position (i.e. because it completed, like in the example above), zip won‘t emit anything anymore. This is called indexed sequencing, which is a way to walk sequences in lockstep. But while zip may stop emitting values early, it won‘t itself complete until all its inner observables complete, making sure each can complete its work.

// Note: Swift also has a zip(_:_:) collection operator. It creates a new collection of tuples with items from both collections. But this is its only implementation. RxSwift offers variants for two to eight observables, plus a variant for collections, like combineLatest does.

// MARK: - Trigger

//Apps have diverse needs and must manage multiple input sources. You’ll often need to accept input from several observables at once. Some will simply trigger actions in your code, while others will provide data. RxSwift has you covered with powerful operators that will make your life easier. Well, your coding life at least!

//You’ll first look at withLatestFrom(_:). Often overlooked by beginners, it’s a useful companion tool when dealing with user interfaces, among other things.

// button                                                            tap!        tap!
// textField                             "Par"   "Pari"      "Paris"
// button withLatestFrom textfield:                                  "Paris"     "Paris"


example(of: "withLatestFrom") {
    let button = PublishSubject<Void>()
    let textField = PublishSubject<String>()
    
    let observable = button.withLatestFrom(textField)
    
    _ = observable.subscribe(onNext: { value in
        print(value)
    })
    
    textField.onNext("Par")
    textField.onNext("Pari")
    textField.onNext("Paris")
    
    button.onNext(())
    button.onNext(())

}


//1. Create two subjects simulating button taps and text field input. Since the button
//carries no real data, you can use Void as an element type.

//2. When button emits a value, ignore it but instead emit the latest value received
//from the simulated text field.

//3. Simulate successive inputs to the text field, which is done by the two successive button taps.

//Simple and straightforward! withLatestFrom(_:) is useful in all situations where you want the current (latest) value emitted from an observable, but only when a particular trigger occurs.


//A close relative to withLatestFrom(_:) is the sample(_:) operator.

// button                                                            tap!        tap!
// textField                             "Par"   "Pari"      "Paris"
// textfield sample button:                                          "Paris"

//It does nearly the same thing with just one variation: each time the trigger observable emits a value, sample(_:) emits the latest value from the “other” observable, but only if it arrived since the last trigger. If no new data arrived, sample(_:) won’t emit anything.

example(of: "sample") {
    let button = PublishSubject<Void>()
    let textField = PublishSubject<String>()
    
//    let observable = button.withLatestFrom(textField)
    let observable = textField.sample(button)
    
    _ = observable.subscribe(onNext: { value in
        print(value)
    })
    
    textField.onNext("Par")
    textField.onNext("Pari")
    textField.onNext("Paris")
    
    button.onNext(())
    button.onNext(())
//    Notice that "Paris" now prints only once! This is because the text field didn‘t emit a new value between your two fake button taps. You could have achieved the same behavior by adding a distinctUntilChanged() to the withLatestFrom(_:) observable, but smallest possible operator chains are the Zen of Rx.

    textField.onNext("Paris2")
    button.onNext(())
}

//Note: Don’t forget that withLatestFrom(_:) takes the data observable as a parameter, while sample(_:) takes the trigger observable as a parameter. This can easily be a source of mistakes — so be careful!


 // MARK: - Switches

//RxSwift comes with two main so-called “switching” operators: amb(_:) and switchLatest(). They both allow you to produce an observable sequence by switching between the events of the combined or source sequences. This allows you to decide which sequence’s events will the subscriber receive at runtime.
//Let’s look at amb(_:) first. Think of “amb” as in “ambiguous”.

example(of: "amb") {
  let left = PublishSubject<String>()
  let right = PublishSubject<String>()
// 1
  let observable = left.amb(right)
  _ = observable.subscribe(onNext: { value in
    print(value)
  })
// 2
  left.onNext("Lisbon")
  right.onNext("Copenhagen")
  left.onNext("London")
  left.onNext("Madrid")
  right.onNext("Vienna")
  left.onCompleted()
  right.onCompleted()
}


// left          :       1   2       3
// right         :   4 5          6
// left amb right:   4 5          6

//You’ll notice that the debug output only shows items from the left subject. Here’s what you did:
//1. Create an observable which resolves ambiguity between left and right.
//2. Have both observables send data.
//The amb(_:) operator subscribes to the left and right observables. It waits for any of them to emit an element, then unsubscribes from the other one. After that, it only relays elements from the first active observable. It really does draw its name from the term ambiguous: at first, you don’t know which sequence you’re interested in, and want to decide only when one fires.

//This operator is often overlooked. It has a few select practical applications, such as connecting to redundant servers and sticking with the one that responds first.


// MARK: - switchLatest()

// A more pouplar option is the switchLatest() operator:

example(of: "switchLatest") {
    // 1
    let one = PublishSubject<String>()
    let two = PublishSubject<String>()
    let three = PublishSubject<String>()
    
    let source = PublishSubject<Observable<String>>()
    
    let observable = source.switchLatest()
    let disposable = observable.subscribe(onNext: { value in
        print(value)
    })
    
    source.onNext(one)
    one.onNext("Some text from sequence one") // !
    two.onNext("Some text from sequence two")
    
    source.onNext(two)
    two.onNext("More text from sequence two") // !
    one.onNext("and also from sequence one")
    
    source.onNext(three)
    two.onNext("Why don't you see me?")
    one.onNext("I'm alone, help me")
    three.onNext("Hey it's three. I win.") // !
    
    source.onNext(one)
    one.onNext("Nope. It's me, one!") // !
    
    disposable.dispose()
}

//Notice the few output lines. Your subscription only prints items from the latest sequence pushed to the source observable. This is the purpose of switchLatest().

//Note: Did you notice any similarity between switchLatest() and another operator? You learned about its cousin flatMapLatest(_:) in Chapter 7, “Transforming Operators”. They do pretty much the same thing: flatMapLatest maps the latest value to an observable, then subscribes to it. It keeps only the latest subscription active, just like switchLatest.

// MARK: - Combining elements with a sequence.

//Through your coding adventures in Swift, you may already know about its reduce(_:_:) collection operator. If you don’t, here’s a great opportunity, as this knowledge applies to pure Swift collections as well.

// seq  :                                           1           2       3
// reduce seq with { acc, value -> Int in                               6
//                        return acc + value }

example(of: "reduce") {
    let source = Observable.of(1,3,5,7,9)
    
//    let observable = source.reduce(0, accumulator: +)
    
    let observable = source.reduce(0) { summary, newValue in
        return summary + newValue
    }
    //  The operator `accumulates` a summary value.
    // It starts with the initial value you provide (0).
    // Each time the source observable emits an item, reduce(_:_:) calls your closure to produce a new summary.
    // When the source observable completes, reduce(_:_:) emits the summary value, then completes.
    
    
    _ = observable.subscribe(onNext: { value in
        print(value)
    })
}


// Note: reduce(_:_:) produces its summary (accumulated) value only when the source observable completes.
// Applying this operator to sequences that never complete won’t emit anything. This is a frequent source of confusion and hidden problems.

//A close relative to reduce(_:_:) is the scan(_:accumulator:) operator. Can you spot the difference in the schema below, comparing to the last one above?


// seq  :                                           1           2       3
// reduce seq with { acc, value -> Int in           1           3       6
//                        return acc + value }

example(of: "scan") {
  let source = Observable.of(1, 3, 5, 7, 9)
//  let observable = source.scan(0, accumulator: +)
    let observable = source.scan(0) { summary, newValue in
        return summary + newValue
    }
  _ = observable.subscribe(onNext: { value in
    print(value)
  })
}


//Each time the source observable emits an element, scan(_:accumulator:) invokes your closure. It passes the running value along with the new element, and the closure returns the new accumulated value.
//Like reduce(_:_:), the resulting observable type is the closure return type.
//The range of use cases for scan(_:accumulator:) is quite large; you can use it to
//compute running totals, statistics, states and so on.
//Encapsulating state information within a scan(_:accumulator:) observable is a good idea; you won’t need to use local variables, and it goes away when the source observable completes. You’ll see a couple of neat examples of scan in action in Chapter 20, “RxGesture.”
