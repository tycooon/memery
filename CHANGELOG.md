## [Unreleased]

## [1.4.1] - 2021-06-16
- Under-the-hood refactor & optimizations. ([@tycooon]) [bc503f3]

## [1.4.0] - 2021-03-15
### Fixed
- Fix compatibility with `ActiveSupport::Concern`. ([@tycooon] and [@AlexWayfer]) [#26]

## [1.3.0] - 2020-02-10
### Added
- Allow memoization after including module with Memery. ([@AlexWayfer]) [#23]

### Changed
- Make `memoize` return the method name to allow chaining. ([@JelF]) [#22]

### Fixed
- Fix warnings in Ruby 2.7. ([@AlexWayfer]) [#19], [#25]

## [1.2.0] - 2019-10-19
### Added
- Add `:ttl` option for `memoize` method ([@AlexWayfer]) [#11]
- Add benchmark script ([@AlexWayfer]) [#14]
- Add `.memoized?` method ([@AlexWayfer]) [#17]

## [1.1.0] - 2019-08-05
### Fixed
- Optimize speed and memory for cached values returns. ([@AlexWayfer]) [#10]

## [1.0.0] - 2018-08-31
### Added
- Add `:condition` option for `.memoize` method. ([@AlexWayfer]) [#7]

## [0.6.0] - 2018-04-20
### Added
- Readme example for memoizing class methods. ([@AlexWayfer]) [#3]
- Memery raises `ArgumentError` if method is not defined when you call `memoize`.

## [0.5.0] - 2017-06-12
- Initial public version.

[0.5.0]: https://github.com/tycooon/memery/tree/v0.5.0
[0.6.0]: https://github.com/tycooon/memery/compare/v0.5.0...v0.6.0
[1.0.0]: https://github.com/tycooon/memery/compare/v0.6.0...v1.0.0
[1.1.0]: https://github.com/tycooon/memery/compare/v1.0.0...v1.1.0
[1.2.0]: https://github.com/tycooon/memery/compare/v1.1.0...v1.2.0
[1.3.0]: https://github.com/tycooon/memery/compare/v1.2.0...v1.3.0
[1.4.0]: https://github.com/tycooon/memery/compare/v1.3.0...v1.4.0
[1.4.1]: https://github.com/tycooon/memery/compare/v1.4.0...v1.4.1
[Unreleased]: https://github.com/tycooon/memery/compare/v1.4.1...HEAD

[@tycooon]: https://github.com/tycooon
[@AlexWayfer]: https://github.com/AlexWayfer
[@JelF]: https://github.com/JelF

[#3]: https://github.com/tycooon/memery/pull/3
[#7]: https://github.com/tycooon/memery/pull/7
[#10]: https://github.com/tycooon/memery/pull/10
[#11]: https://github.com/tycooon/memery/pull/11
[#14]: https://github.com/tycooon/memery/pull/14
[#17]: https://github.com/tycooon/memery/pull/17
[#19]: https://github.com/tycooon/memery/pull/19
[#22]: https://github.com/tycooon/memery/pull/22
[#23]: https://github.com/tycooon/memery/pull/23
[#25]: https://github.com/tycooon/memery/pull/25
[#26]: https://github.com/tycooon/memery/pull/26
[bc503f3]: https://github.com/tycooon/memery/commit/bc503f36103a71245aa47aeb30225a48fb39438e
