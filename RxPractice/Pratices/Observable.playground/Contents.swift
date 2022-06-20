import UIKit
import RxSwift



func example(of title: String, closure: () -> Void) {
    print("-------------  example of \(title)  -------------")
    closure()
}


// MARK: - Observables


/*
 
 Observable == Observable sequence == Sequence

  An Observable is just a sequence, with some special powers.

  - Asynchronous.

  

  Observables produce events over a period of time, which is referred to as emitting.

  

  Events can contain values, such as numbers or instances of a custom type, or they can be recognized by gestures, such as taps.

  

  When an observable emits an element, it does so in what’s known as a 'next event'.

  

  completed event: terminated.

  -> can no longer emit anything.

  

  The observable emitted an error event containing the error.

  This is the same as when an observable terminates normally with a completed event.

  

  If an observable emits an error event, it is also terminated and can no longer emit anything else.

  

  key points

  

  1. An observable emits next events that contain elements.

  

  2. It can continue to do this until a terminating event is emitted ( an error or completed event.)

  

  3. Once an observable is terminated, it can no longer emit events.
 
 */


// MARK: - Actual implementation in the RxSwift source code
/*
 public enum Event<Element> {
     /// Next element is produced.
         case next(Element)

         /// Sequence terminated with an error.
         case error(Swift.Error)

         /// Sequence completed successfully.
         case completed
 }
 */


//completed events are simply stop events that don't contain any data.


// MARK: - Creating Observables

example(of: "just, of, from") {
    let one = 1
    let two = 2
    let three = 3

//     Create an observable sequence of type Int
//     just : create an observable sequence containing just a single element.

    let _ = Observable<Int>.just(one)



//    creates a new Observable instance with a variable number of elements. (variadic parameter)
//     Pass an array to 'of' when you want the create an observable array.

    let _ = Observable.of(one, two ,three) // Observable<Int>

    let _ = Observable.of([one, two, three])  //  Observable<[Int]>

    //  The 'from' operator creates an observable of individual elements from an array of typed elements.
    let _ = Observable.from([one, two, three]) //  Observable<Int>
}


//An observable won't send events, or perform any work, until it has a subscriber.

//An observable is really a sequence definition, and subscribing to an observable is really more like calling next() on an Iterator in the Swift standard library.


func iteratorSample() {
    let sequence = 0 ..< 3
    // makeIterator() : Returns an iterator over the elements of the collection.
    var iterator = sequence.makeIterator()
    
    // next() -> Int? : Advances to the next element and returns it, or nil if no next element exists.
    while let n = iterator.next() {
        print(n)
    }
}

iteratorSample()

// Subscribing to observables is more streamlined.

// You can also add handlers for each event type an observable can emit.

example(of: "subscribe") {
    let one = 1
    let two = 2
    let three = 3
    
    let observable = Observable.of(one, two, three)
    
    // Subscribes an event handler to an observable sequence.
    // func subscribe(_ on: @escaping (Event<E>) -> Void) -> Disposable
    // Parameter on : Action to invoke for each event in the observable sequence.
    observable.subscribe { event in
        print(event)
    }
    /*
     next(1)
     next(2)
     next(3)
     completed
     */
    
    // Event has an element property, which is an optional value because only 'next' events have an element.
    // only the elements are printed, not the 'events' containing the elements, nor the 'completed' event.
    observable.subscribe { event in
        if let element = event.element {
            print(element)
        }
    }
    /*
     1  2  3
     */
    
    // shortcut for above code
    observable.subscribe(onNext: { element in
        print(element)
    })
    /*
     1  2  3
     */
}

// observable of zero elements

// The 'empty' operator creates an empty observable sequence with zero elements; it will only emit a 'completed' event.

// empty observable is handy when you want to return an observable that 'immediately terminates' or 'intentionally has zero values'.


example(of: "empty") {
    
    // An observable must be defined as a specific type if it cannot be inferred.
    // Void is typically used because nothing is going to be emitted.
    let _ = Observable<Void>.empty()
        .subscribe(onNext: { element in
            print(element) // not printed
            // .completed event does not include an element.
        }, onCompleted: {
            print("completed!")
        })
    // completed!
}

// the 'never' operator creates an observable that doesn’t emit anything and "never terminates".
// It can be used to represent an infinite duration.

example(of: "never") {
    let observable = Observable<Void>.never()
    
    observable.subscribe(onNext: { element in
        print(element)
    }, onCompleted: {
        print("Completed") // not printed
    })
}


example(of: "range") {
    // Create an observable using the range operator.
    let observable = Observable<Int>.range(start: 1, count: 10)
    
    observable
        .subscribe(onNext: { i in
            let n = Double(i)
            let fibonacci = Int(
                ((pow(1.61803, n) - pow(0.61803, n)) /
                 2.23606).rounded()
            )
            print(fibonacci)
        })
}

// MARK: - Disposing and terminating

example(of: "dispose") {
    // create an observable of strings.
    let observable = Observable.of("A", "B", "C")
    
    // subscribe to the observable, this time saving the returned 'Disposable' as a local constant called `subscription`
    let subscription = observable.subscribe { event in
        print(event)
    }
    
    // To explicitly cancel a subscription, call dispose() on it.
    
    // After you cancel the subscription, or dispose of it,
    // the observable in the current example will stop emitting events.
    subscription.dispose()
    // next(A)   next(B)   next(C)   completed
}

// This is the pattern you’ll use most frequently:

// creating and subscribing to an observable,

// and immediately adding the subscription to a dispose bag.


example(of: "Dispose") {
    // Thread safe bag that disposes added disposables on deinit
    let disposeBag = DisposeBag()
    
    Observable.of("A","B","C")
        .subscribe {
            print($0)
        } // adds self to bag, Add the returned Disposable from subscribe to the dispose bag
        .disposed(by: disposeBag)
    
    // next(A)   next(B)   next(C)   completed
}


// If you forget to add a subscription to a dispose bag,

// or manually call dispose on it when you're done with the subscription,

// or in some other way cause the observable to terminate at some point,

// you will probably leak memory.


//Don’t worry if you forget; the Swift compiler should warn you about unused disposables.



// Using the create operator is another way to specify all the events an observable will emit to subscribers.



example(of: "create") {
    
    enum MyError: Error {
        case anError
    }
    let disposeBag = DisposeBag()
    
    //    .create : Creates an observable sequence from a specified subscribe method implementation.
//        static func create(_ subscribe: @escaping (AnyObserver<String>) -> Disposable) -> Observable<String>
    
//    The create operator takes a single parameter named subscribe. Its job is to provide the implementation of calling subscribe on the observable.
//  **In other words, it defines all the events that will be emitted to subscribers.
    
    Observable<String>.create { observer in // return Observable<String> if .subscribe not attached
        
        observer.onNext("1")
//        observer.onError(MyError.anError)
//        observer.onCompleted()
        observer.onNext("?")
//        Return a disposable, defining what happens when your observable is terminated or disposed of; in this case, no cleanup is needed so you return an empty disposable.
        
//        subscribe operators must return a disposable representing the subscription,
//        so you use Disposables.create() to create a disposable.
        return Disposables.create()
    }
    .subscribe(
        onNext: {print($0)},
        onError: { print($0)},
        onCompleted: { print("Completed")},
        onDisposed: { print("Disposed")})
    .disposed(by: disposeBag) // prevent memory leak
    
    /*
     1
     Completed
     Disposed
     */
}


// MARK: - Creating observable factories

//Rather than creating an observable that waits around for subscribers, it’s possible to create observable factories that vend a new observable to each subscriber.

example(of: "deferred") {
    let disposeBag = DisposeBag()
    
    var flip = false
    //     Returns an observable sequence that invokes the specified factory function whenever a new observer subscribes.
    //    static func deferred(_ observableFactory: @escaping () throws -> Observable<Int>) -> Observable<Int>
    let factory: Observable<Int> = Observable.deferred {
        // happens each time factory is subscribed to.
        flip.toggle()
        
        if flip {
            return Observable.of(1,2,3)
        } else {
            return Observable.of(4,5,6)
        }
    }
    
    for _ in 0 ... 3 {
        factory.subscribe(onNext: {
            print($0, terminator: "")
        })
        .disposed(by: disposeBag)

        print()
    }
    /*
     123
     456
     123
     456
     */
}
