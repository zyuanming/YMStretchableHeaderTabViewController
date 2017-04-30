# Introduction

**YMStretchableHeaderTabViewController** apply Stretchable header view and Horizontal swipable tab view. It's written in `Swift`

# YMStretchableHeaderTabViewController

`YMStretchableHeaderTabViewController` apply Stretchable header view and Horizontal swipable tab view for iOS.  It was inspired by [AXStretchableHeaderTabViewController](https://github.com/akiroom/AXStretchableHeaderTabViewController).

# Simple Usage

```swift

class FirstViewController: SegmentedViewController {
    let tags: [String] = ["tag1", "tag2", "tag3", "tag4", "tag5", "tag6", "tag7"]

    override func viewDidLoad() {
        super.viewDidLoad()
        var test: [(title: SegmentedControl.SegmentedItem, controller: UIViewController)] = []
        for tagName in tags {
            test.append((.init(value: tagName), SampleDataViewController()))
        }
        setControllersForSegments(contents: test)
    }
}

```

# License
```
Licensed under the MIT License
```
