import Foundation
import RxSwift

let bag = DisposeBag()
func example(of title: String, closure: () -> Void) {
    print("---------- \(title) ----------")
    closure()
}



// MARK: - Intro of Section 2 : Operators


//Operators are the building blocks of Rx, which you can use to transform, process, and react to events emitted by observables.

//Just as you can combine simple arithmetic operators like +, -, and / to create complex math expressions, you can chain and compose together Rx's simple operators to express complex app logic.

//In this chapter, you are going to:

//• Start by looking into filtering operators, which allow you to process some events but ignore others.

//• Move on to transforming operators, which allow you to create and express complex data transformations. You can for example start with a button event, transform that into some kind of input, process that and return some output to show in the app UI.

//• Look into combining operators, which allow for powerful composition of most other operators.

//• Explore operators that allow you to do time based processing: delaying events, grouping events over periods of time, and more. Work though all the chapters, and by the end of this section you'll be able to write simple RxSwift apps!

//Chapter 5: Filtering Operators
//Chapter 6: Filtering Operators in Practice
//Chapter 7: Transforming Operators
//Chapter 8: Transforming Operators in Practice
//Chapter 9: Combining Operators
//Chapter 10: Combining Operators in Practice
//Chapter 11: Time-Based Operators


// MARK: - Chapter 5: Filtering Operators

//This chapter will teach you about RxSwift’s filtering operators you can use to apply conditional constraints to emitted events, so that the subscriber only receives the elements it wants to deal with.

// Ignoring Operators


// ignoreElements : ignore all next events, but allow stop events through, such as completed or error events

//The ignoreElements operator is useful when you only want to be notified when an observable has terminated, via a completed or error event.

example(of: "ignoreElements") {
    let strikes = PublishSubject<String>()
    
    // Subscribe to all strikes’ events, but ignore all next events by using ignoreElements.
     strikes
        .ignoreElements()
        .subscribe { _ in
            print("You're out!")
        }
        .disposed(by: bag)
    
    strikes.onNext("X")
    strikes.onNext("X")
    strikes.onNext("X")
    
    strikes.onCompleted()

//There may be times when you only want to handle the nth (ordinal) element emitted by an observable, such as the third strike.
//For that, you can use elementAt, which takes the index of the element you want to receive, and ignores everything else. In the marble diagram, elementAt is passed an index of 1, so it only lets through the second element.



example(of: "elementAt") {
    let strikes = PublishSubject<String>()
    
    // subscribe to the next events, ignoring all but the 3rd next event, found at index 2.
    strikes
        .element(at: 2)
        .subscribe(onNext: { _ in
            print("you're out!")
        })
        .disposed(by: bag)
    
    strikes.onNext("X")
    strikes.onNext("X")
    strikes.onNext("X")
}

// An interesting fact about element(at:): As soon as an element is emitted at the provided index, the subscription is terminated.

//ignoreElements and elementAt are filtering elements emitted by an observable.
//When your filtering needs go beyond all or one, use the filter operator.

//It takes a predicate closure and applies it to every element emitted, allowing through only those elements for which the predicate resolves to true.

//ignoreElements and elementAt are filtering elements emitted by an observable. When your filtering needs go beyond all or one, use the filter operator. It takes a predicate closure and applies it to every element emitted, allowing through only those elements for which the predicate resolves to true.

// Filter
example(of: "filter") {
    Observable.of(1,2,3,4,5,6)
        .filter { $0.isMultiple(of: 2)}
        .subscribe(onNext: {
            print($0)
        })
    //     You use the filter operator to apply a conditional constraint to prevent odd numbers from getting through.
    
    //     You subscribe and print out the elements that pass the filter predicate.
        .disposed(by: bag)
}


// Skipping Operators
// skip: skip a certain number of elements
//It lets you ignore the first n elements, where n is the number you pass as its parameter.

example(of: "skip") {
    // skip the first 3 elements and subscribe to next events
    Observable.of("A", "B", "C", "D", "E", "F")
        .skip(3)
        .subscribe(onNext: {
            print($0)
        })
        .disposed(by: bag)
}

//There’s a small family of skip operators. Like filter, skipWhile lets you include a predicate to determine what is skipped.
//However, unlike filter, which filters elements for the life of the subscription, skipWhile only skips up until something is not skipped, and then it lets everything else through from that point on.
//And with skipWhile, returning true will cause the element to be skipped, and returning false will let it through. It’s the opposite of filter.
                                                                                                                                                                                
// skipWhile
//There’s a small family of skip operators. Like filter, skipWhile lets you include a predicate to determine what is skipped. However, unlike filter, which filters elements for the life of the subscription, skipWhile only skips up until something is not skipped, and then it lets everything else through from that point on.
//And with skipWhile, returning true will cause the element to be skipped, and returning false will let it through. It’s the opposite of filter.
example(of: "skipwhile") {
    Observable.of(2,2,3,4,4,1)
        .skipWhile({ int in
            int < 3
        })
        .subscribe(onNext: {
            print($0)
        })
        .disposed(by: bag)
}
//Remember, skip only skips elements up until the first element is let through, and then all remaining elements are allowed through.



//So far, you’ve filtered based on a static condition. What if you wanted to dynamically filter elements based on another observable? There are a couple of operators to choose from.

//The first is skipUntil, which will keep skipping elements from the source observable — the one you’re subscribing to — until some other trigger observable emits. In this marble diagram, skipUntil ignores elements emitted by the source observable on the top line until the trigger observable on second line emits a next event. Then it stops skipping and lets everything through from that point on.


//The first is skipUntil, which will keep skipping elements from the source observable — the one you’re subscribing to — until some other trigger observable emits.


example(of: "skipUntil") {
//    Create a subject to model the data you want to work with, and another subject to act as a trigger.
    let subject = PublishSubject<String>()
    let trigger = PublishSubject<String>()
    
    subject
//    Use skipUntil and pass the trigger subject. When trigger emits, skipUntil stops skipping.
        .skip(until: trigger)
        .subscribe(onNext: {
            print($0)
        })
        .disposed(by: bag)
    
    subject.onNext("A")
    subject.onNext("B")
    trigger.onNext("X")
    subject.onNext("C")
}


// MARK: - Taking operators
//Taking is the opposite of skipping.
//When you want to take elements, RxSwift has you covered. The first taking operator you’ll learn about is take, which will take the first of the number of elements you specified.

example(of: "take") {
    Observable.of(1,2,3,4,5,6)
//    Take the first 3 elements using take.
        .take(3)
        .subscribe(onNext: {
            print($0)
        })
        .disposed(by: bag)
}

// takeWhile
//The takeWhile operator works similarly to skipWhile, except you’re taking instead of skipping.

//Additionally, if you want to reference the index of the element being emitted, you can use the enumerated operator.
//It yields tuples containing the index and element of each emitted element from an observable, similar to how the enumerated method in the Swift Standard Library works.

example(of: "takeWhile") {
    Observable.of(2,2,4,4,6,6)
//    Use the enumerated operator to get tuples containing the index and value of each element emitted.
        .enumerated()
//    destructure the tuple into individual arguments.
        .take(while: { index, integer in
//    Pass a predicate that will take elements until the condition fails.

            integer.isMultiple(of: 2) && index < 3
        })
//    Use map to reach into the tuple returned from takeWhile and get the element.
        .map(\.element)
        .subscribe(onNext: {
            print($0)
        })
        .disposed(by: bag) // 2 2 4
}

//The result is you only receive elements as long as the integers are even, up to when the element’s index is 3 or greater.



// takeUntil:  take elements until the predicate is met.
//It also takes a behavior argument for its first parameter that specifies
//if you want to include or exclude the last element matching the predictate.

example(of: "takeUntil") {
    Observable.of(1,2,3,4,5)
//        .take(until: {
//            $0.isMultiple(of: 4)
//        }, behavior: .exclusive)
        .take(until: {
            $0.isMultiple(of: 4)
        })
        .subscribe(onNext: {
            print($0)
        })
        .disposed(by: bag)
    // inclusive: 1, 2, 3, 4
    // exclusive: 1, 2, 3 (default)
}

//Like skipUntil, there is a variation of takeUntil also works with a trigger observable.

example(of: "takeUntil trigger") {
    let subject = PublishSubject<String>()
    let trigger = PublishSubject<String>()
    
    subject
    // Use takeUntil, passing the trigger that will cause takeUntil to stop taking once it emits.
        .take(until: trigger)
        .subscribe(onNext: {
            print($0)
        })
        .disposed(by: bag)
    
    subject.onNext("1")
    subject.onNext("2")
    
    trigger.onNext("X")
    
    subject.onNext("3")
    // 1  2
}


    
//There is a way to use takeUntil with an API from the RxCocoa library to dispose of a subscription, instead of adding it to a dispose bag.
//You’ll learn about RxCocoa in Section III, “iOS Apps with RxCocoa.” Generally speaking, the safe bet to avoid leaking memory is to always add your subscriptions to a dispose bag.
// However, for the sake of completeness, here’s an example of how you would use takeUntil with RxCocoa

/*
_ = someObservable
    .takeUntil(self.rx.deallocated)
    .subscribe(onNext: {
print($0) })
*/

//In the above code, the deallocation of self is the trigger that causes takeUntil to stop taking, where self is typically a view controller or view model.


// Distinct Operators

//The next couple of operators let you prevent duplicate contiguous items from getting through.

//distinctUntilChanged only prevents duplicates that are right next to each other

example(of: "distinctUntilChanged") {
    Observable.of("A", "A", "B", "B", "A")
//    prevent sequential duplicates from getting through.
        .distinctUntilChanged()
        .subscribe(onNext: {
            print($0)
        })
        .disposed(by: bag) // A B A
}

//These are instances of String, which conform to Equatable. However, you can optionally use distinctUntilChanged(_:) to provide your own custom logic to test for equality; the parameter you pass is a comparer.

struct TestStruct {
    var value: Int
    var name: String
}

example(of: "distinctUntilChanged(_:)") {
    let a1 = TestStruct(value: 1, name: "a")
    let a2 = TestStruct(value: 2, name: "a")
    let b1 = TestStruct(value: 1, name: "b")
    
//    let subject =
    Observable.of(a1, b1, a1, a2)
        .distinctUntilChanged {
            $0.value == $1.value
        }
        .subscribe(onNext: {
            print($0)
        })
        .disposed(by: bag) // a1 a2
}


// MARK: - Challenge

//Note: The toArray operator returns a Single, which you learned about in Chapter 2, “Observables.” The convenience syntax to subscribe to a Single is subscribe(onSuccess:onError:). If you only want to handle receiving the element if the single is successful, only implement the onSuccess handler

example(of: "Challenge 1") {
//  let disposeBag = DisposeBag()
  
  let contacts = [
    "603-555-1212": "Florent",
    "212-555-1212": "Shai",
    "408-555-1212": "Marin",
    "617-555-1212": "Scott"
  ]
  
  func phoneNumber(from inputs: [Int]) -> String {
    var phone = inputs.map(String.init).joined()
    
    phone.insert("-", at: phone.index(
      phone.startIndex,
      offsetBy: 3)
    )
    
    phone.insert("-", at: phone.index(
      phone.startIndex,
      offsetBy: 7)
    )
    
    return phone
  }
  
  let input = PublishSubject<Int>()
  
  // Add your code here
  input
        .skip(while: { $0 == 0 })
        .filter { $0 < 10 }
        .take(10)
        .toArray() // -> Single<[Int]>
//        .subscribe(onNext: {
//            print($0)
//        })
        .subscribe(onSuccess: { result in
//            print(result)
//            print(phoneNumber(from: result))
            let resultPhoneNumber = phoneNumber(from: result)
            if let found = contacts[resultPhoneNumber] {
                print("found: \(found)")
            } else {
                print("Contact not found with \(resultPhoneNumber)")
            }
            
        })
        .disposed(by: bag)
    
  
  input.onNext(0)
  input.onNext(603)
  
  input.onNext(2)
  input.onNext(1)
  
  // Confirm that 7 results in "Contact not found",
  // and then change to 2 and confirm that Shai is found
    
  input.onNext(2)
  
  "5551212".forEach {
    if let number = (Int("\($0)")) {
      input.onNext(number)
    }
  }
  
  input.onNext(9)
}
