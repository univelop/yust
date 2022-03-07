## 3.0.0-dev.5 - 2022-03-07

* Fix iOS App initialization

## 3.0.0-dev.4 - 2022-03-05

* Fix iOS App initialization

## 3.0.0-dev.3 - 2022-03-04

* Textfield validation
* Traversal object helper
* Remove yust store
* Improve state management
* Rework json logic

## 3.0.0-dev.2 - 2022-02-17

* Scrollbars for web
* Descriptions for alerts
* Unit test support
* Improve read only mode
* Improve timestamp handling
* Fix bugs

## 3.0.0-dev.1 - 2022-01-08

* New widget layout
* Add pagination for lists
* Download images
* Improve routing
* Fix bugs

## 2.6.1 - 2021-11-29

* Fix bugs

## 2.6.0 - 2021-11-28

* Improve text field
* Improve firebase emulators
* Fix bugs

## 2.5.3 - 2021-10-23

* Add validator to text field dialog
* Improve date and time picker
* Support firebase emulator
* Improve image picker and galery

## 2.5.2 - 2021-10-02

* Add multiple image support to image picker

## 2.5.1 - 2021-10-01

* Optimize widgets for smaller screens

## 2.5.0 - 2021-10-01

* Migrate to Flutter 2.5.1
* Improve text and number fields
* Improve image picker
* Disable persistence for browser
* Fix bugs

## 2.4.0 - 2021-08-27

* Add validation to input fields
* Add controllers to input fields
* Fix bugs

## 2.3.0 - 2021-08-07

* Improve focus handling
* Improve timestamp convertion
* Fix bugs

## 2.2.0 - 2021-07-02

* Add checkbox control for switch
* Support Firebase subcollections
* Add quality setting to image picker
* Improve file offline handling

## 2.1.1 - 2021-06-03

* Improve null safety

## 2.1.0 - 2021-05-30

* Improve text dialog
* Improve file opening
* Improve null safety

## 2.0.0 - 2021-05-18

* Add null safety

## 1.9.3 - 2021-05-03

* Add read only to widgets
* Change time picker input hint
* Add pop up title to time picker

## 1.9.2 - 2021-04-12

* Improve number field

## 1.9.1 - 2021-04-11

* Upgrade firebase packages
* Add YustSerializable for a bette toJson support

## 1.9.0 - 2021-04-01

* Upgrade to Flutter 2
* Add time picker keyboard support

## 1.8.4 - 2021-03-27

* Fix bilding issue

## 1.8.3 - 2021-03-26

* Improve mapToJson support
* Remove web helper
* Fix flutter web support

## 1.8.2 - 2021-03-09

* Fix file exists

## 1.8.1 - 2021-03-08

* Fix file upload

## 1.8.0 - 2021-03-07

* Add button tile
* Add prefix icon to text and number field

## 1.7.0 - 2021-02-26

* Update firebase
* Support flutter web directly

## 1.6.1 - 2021-02-22

* Improve mapToJson

## 1.6.0 - 2021-02-19

* Improve date time handling
* Add offline check
* Improve yust doc

Breaking changes:
* `YustDoc.mapFromJson` returs DateTime values instead of Timestamp values.
* Therefore `YustDoc.mapToJson` transfers DateTime values to Timestamps.

## 1.5.0 - 2021-02-19

* Add time picker
* Add input tile
* Migrate to Flutter 1.12
* Improve reset password
* Improve image picker
* Improve resize image
* Improve text field
* Improve map from json
* Improve modal buttons
* Usability improvements
* Fix bugs

## 1.4.0 - 2020-11-14

* Add image handling for web
* Add multiple image picking
* Add file picker
* Improve authentication
* Add file download
* Add file exisit check
* Fix bugs

## 1.3.0 - 2020-09-24

* Update firebase
* Add image picker
* Improve number field

## 1.2.2 - 2020-09-11

* Fix widget overflows

## 1.2.1 - 2020-09-08

* Improve serialization

## 1.2.0 - 2020-09-07

* Add onEditingComplete to widgets
* Improve store builder

## 1.1.0 - 2020-09-01

* Add prefix icon to widgets

## 1.0.1 - 2020-08-20

* Improve switch

## 1.0.0 - 2020-08-01

* Add created by, modified at, modified by
* Improve number field
* Improve authentication
* Improve widgets

## 0.5.0 - 2020-06-05

* Improve authentication
* Improve filtering
* Improve user subscriber
* Support Flutter Web
* Support Firestore timestamps:
  Set `useTimestamps` in `Yust.initialize` to `true`
* Improve JSON Serialization
* Add useful widgets
* Add documentation
* Fix issues

Breaking changes:
* `createdAt` in YustDoc changed type from String to DateTime.
* Use `formatDate` and `formatTime` in YustService if you switch to Firebase timestamps. Use `formatIsoDate` and `formatIsoTime` for the old ISO Datetime format.

## 0.4.0 - 2020-01-17

* Update to Flutter 1.12
* Add insights to doc builder
* Improve date picker
* Improve push notifications
* Enable offline persistance
* Improve sign in and sign up
* Improve routing
* Make user extendable
* Improve descanding ordering

## 0.3.0 - 2019-10-25

* Improve doc builder
* Add sorting for queries
* Add getDocOnce and getDocsOnce queries
* Add switch tile widget
* Add notifications and badges
* Add progress button
* Add account edit screen
* Use firebase document merging
* Improvements and hotfixes

## 0.2.0 - 2019-07-31

* Improve filters
* Add random string generator
* Add account screen
* Improvements and hotfixes

## 0.1.0 - 2019-07-23

* Initial release
* Firebase Authentication
* Firestore load and save services
* Widgets to handle firebase requests
