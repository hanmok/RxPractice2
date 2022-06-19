import UIKit
import RxSwift

let bag = DisposeBag()

func example(of title: String, closure: () -> Void) {
    print("---------- \(title) ----------")
    closure()
}

// MARK: - Transforming elements

// toArray

//Observables emit elements individually, but you will frequently want to work with collections, such as when you’re binding an observable to a table or collection view, which you’ll learn how to do later in the book.
// A convenient way to transform an observable of individual elements into an array of all those elements is by using toArray.


//toArray will convert an observable sequence of elements into an array of those elements once the observable completes. The toArray operator returns a Single.
// Recall from Chapter 2, “Observables,” that Single is a trait that emits either a success event containing the value, or an error event containing the error.
//In this case, it will emit a success event containing the array to subscribers.

example(of: "toArray") {
    Observable.of("A", "B", "C")
//    transform the individual elements into an array.
        .toArray()
        .subscribe(onSuccess: {
            print($0)
        })
        .disposed(by: bag)
}



// map

//RxSwift’s map operator works just like Swift’s standard map, except it operates on observables.

example(of: "map") {
    let formatter = NumberFormatter()
    formatter.numberStyle = .spellOut
    
    Observable<Int>.of(123, 4, 56)
//    use map, passing a closure that gets and returns the result of using the formatter to return the number’s spelled out string — or an empty string if that operation returns nil.
        .map {
            formatter.string(for: $0) ?? ""
        }
        .subscribe(onNext: {
            print($0)
        })
        .disposed(by: bag)
}


example(of: "enumerated and map") {
    Observable.of(1,2,3,4,5,6)
//    Use enumerated to produce tuple pairs of each element and its index.
        .enumerated()
//    Use map, and destructure the tuple into individual arguments
        .map { index, integer in
            index > 2 ? integer * 2 : integer
        }
        .subscribe(onNext: {
            print($0)
        })
        .disposed(by: bag)
}


//The compactMap operator is a combination of the map and filter operators that specifically filters out nil values, similarly to its counterpart in the Swift standard library.

example(of: "compactMap") {
//    Create an observable of String?, which the of operator infers from the values.
    Observable.of("To", "be", nil, "or", "not", "to", "be", nil)
//    Use the compactMap operator to retrieve unwrapped value, and filter out nils.
        .compactMap { $0 }
//    Use toArray to convert the observable into a Single that emits an array of all its values.
        .toArray() // -> Single<[String]>
        .map { $0.joined(separator: " ") } // join the values together
        .subscribe(onSuccess: {
            print($0)
        })
        .disposed(by: bag)
}


//Up until this point, you’ve worked with observables of regular values. You may have wondered at some point, “How do I work with observables that are properties of observables?” Enter the matrix.


// MARK: - Transforming inner observables
struct Student {
    let score: BehaviorSubject<Int>
}

//RxSwift includes a few operators in the flatMap family that allow you to reach into an observable and work with its observable properties. You’re going to learn how to use the two most common ones here.

//The first one you’ll learn about is flatMap. The documentation for flatMap says: “Projects each element of an observable sequence to an observable sequence and merges the resulting observable sequences into one observable sequence.” Whoa!

// reference page: 162 ~ 163
//flatMap projects and transforms an observable value of an observable, and
//then flattens it down to a target observable.

example(of: "flatMap") {
//    create two instances of Student, laura and charlotte.
    let laura = Student(score: BehaviorSubject(value: 80))
    let charlotte = Student(score: BehaviorSubject(value: 90))
//    create a source subject of type Student.
    let student = PublishSubject<Student>()
//    use flatMap to reach into the student subject and project its score.
    student
        .flatMap {
            $0.score
        } // 80 85 90 95 100
//        .flatMapLatest({
//            $0.score
//        }) // 80 85 90 100
        .subscribe(onNext: { int in
            print(int)
        })
        .disposed(by: bag)
    
    
    student.onNext(laura)
    laura.score.onNext(85)
    
    student.onNext(charlotte)

    laura.score.onNext(95)
//        This is because flatMap keeps up with each and every observable it creates, one for each element added onto the source observable.
//    Now change charlotte’s score by adding the following code, just to verify that both observables are being monitored and changes projected:
    charlotte.score.onNext(100)
}

//To recap, flatMap keeps projecting changes from each observable. However, when you only want to keep up with the latest element in the source observable, use the flatMapLatest operator.



//The flatMapLatest operator is actually a combination of two operators: map and switchLatest. You’ll learn about switchLatest in the next chapter, “Combining Operators,” but you’re getting a sneak peek here. switchLatest will produce values from the most recent observable, and unsubscribe from the previous observable.


//Here’s the documentation for flatMapLatest: “Projects each element of an observable sequence into a new sequence of observable sequences and then transforms an observable sequence of observable sequences into an observable sequence producing values `only` from the most recent observable sequence.”

// That’s a lot to take in, however you’ve already learned flatMap and this one’s not much different. Check out the marble diagram of flatMapLatest.

//flatMapLatest works just like flatMap to reach into an observable element to access its observable property and project it onto a new sequence for each element of the source observable.
//Those elements are flattened down into a target observable that will provide elements to the subscriber.
//What makes flatMapLatest different is that it will automatically switch to the latest observable and unsubscribe from the previous one.


//Are you wondering when would you use flatMap for flatMapLatest? One of the most common use cases for flatMapLatest is with networking operations, which you’ll do later in the book.
//Imagine that you’re implementing type-ahead search. As the user types each letter, s, w, i, f, t, you want to execute a new search and ignore results from the previous one. flatMapLatest is how you do that.




// MARK: - Observing events

//At times you may want to convert an observable into an observable of its events.
//One typical scenario where this is useful is when you do not have control over an observable that has observable properties, and you want to handle error events to avoid terminating outer sequences.

example(of: "materialize and dematerialize") {
    
    enum MyError: Error {
        case anError
    }
    
    let laura = Student(score: BehaviorSubject(value: 80))
    let charlotte = Student(score: BehaviorSubject(value: 100))
    
    let student = BehaviorSubject(value: laura)
    
    let studentScore = student // Observable<Int> -> Observable<Event<Int>>
        .flatMapLatest {
//            $0.score
            // Convert any Observable into an Observable of its events.
//            The error still causes the studentScore to terminate, but not the outer student observable
            $0.score.materialize() // -> Observable<Event<Int>>
        }
    // However, now you’re dealing with events, not elements. That’s where dematerialize comes in. It will convert a materialized observable back into its original form.
    
    studentScore
        .filter {
            guard $0.error == nil else {
                print($0.error!)
                return false
            }
            return true
        }
    // Use dematerialize to return the studentScore observable to its original form, emitting scores and stop events, not events of scores and stop events.
        .dematerialize()
        .subscribe(onNext: {
            print($0)
        })
        .disposed(by: bag)
    
    laura.score.onNext(85)
    laura.score.onError(MyError.anError)
    // This error is unhandled.
    // The studentScore observable terminates, and so does the outer student observable
    laura.score.onNext(90)
    
    student.onNext(charlotte)
    // Using the materialize operator, you can wrap each event emitted by an observable `in` an observable.
    
}

//Now your student observable is protected by errors on its inner score observable. The error is printed and laura’s studentScore is terminated, so adding a new score onto her does nothing. But when you add charlotte onto the student subject, her score is printed:





// MARK: - Challenge

//Note: The toArray operator returns a Single, which you learned about in Chapter 2, “Observables.” The convenience syntax to subscribe to a Single is subscribe(onSuccess:onError:). If you only want to handle receiving the element if the single is successful, only implement the onSuccess handler

example(of: "Challenge 122") {
  let disposeBag = DisposeBag()
  
  let contacts = [
    "603-555-1212": "Florent",
    "212-555-1212": "Shai",
    "408-555-1212": "Marin",
    "617-555-1212": "Scott"
  ]
  
  let convert: (String) -> Int? = { value in
    if let number = Int(value),
       number < 10 {
      return number
    }
    
    let keyMap: [String: Int] = [
      "abc": 2, "def": 3, "ghi": 4,
      "jkl": 5, "mno": 6, "pqrs": 7,
      "tuv": 8, "wxyz": 9
    ]
    
    let converted = keyMap
      .filter { $0.key.contains(value.lowercased()) }
      .map(\.value)
      .first
    
    return converted
  }
    
//    print(convert("abc")) // returns optional(2)
    
  let format: ([Int]) -> String = {
    var phone = $0.map(String.init).joined()
    
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
  
  let dial: (String) -> String = {
    if let contact = contacts[$0] {
      return "Dialing \(contact) (\($0))..."
    } else {
      return "Contact not found"
    }
  }
  
  let input = PublishSubject<String>()
  
//    input
  // Add your code here
    input.asObservable()
        .map { convert($0) }
        .compactMap { $0 }
        .skip(while: { $0 == 0 })
        .filter { $0 < 10 }
        .take(10)
        .toArray() // -> Single<[Int]>
        .map { format($0) } // -> Single<Result>
        .subscribe(onSuccess: {
            print(dial($0))
        })
        .disposed(by: bag)
    
  
  input.onNext("")
  input.onNext("0")
  input.onNext("408")
  
  input.onNext("6")
  input.onNext("")
  input.onNext("0")
  input.onNext("3")
  
  "JKL1A1B".forEach {
    input.onNext("\($0)")
  }
  
  input.onNext("9")
}
