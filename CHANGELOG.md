# Changelog

All notable changes to this project will be documented in this file.

The format is mainly based on [Keep a Changelog](http://keepachangelog.com/)
and this project adheres to [Semantic Versioning](http://semver.org/).

## Unreleased

* Fixed: No output of the last state for the transaction log shrinking

## 0.4.1 - 2020-07-10

* Fixed: Issue not shrinking a transaction log im some cases

## 0.4.0 - 2020-07-08

* Added: New command to shrink a transaction log

## 0.3.0 - 2020-07-02

* Added: New command to invoke a database copy
* Added: Add edition to the Test-SqlConnection command
* Fixed: Connection string not in result object
* Fixed: Prevent the password leaking in an exception message

## 0.2.0 - 2020-05-17

* Changed: Add quiet option for Test-SqlConnection command
* Fixed: Wrap error for missing SERVER STATE PERMISSIONS in Test-SqlConnection

## 0.1.0 - 2020-03-05

* Added: Initial release with just Test-SqlConnection command
