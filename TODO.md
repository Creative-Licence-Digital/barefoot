* Clean up helper methods, remove duplicate functionality where possible
* Extra helper methods for (param, done) methods that return objects and arrays?
* Make a bf.HttpRequest and bf.HttpResponse class that gives you access to the
  underlying node request/response and make webService/webPage use these.
* Since we never `return` anything, we could conceivably return promises from
  all of our methods and have a dual promise and callback library (he he).
