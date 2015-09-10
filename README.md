# VirtualTourist
Project 4 of my Udacity iOS Nanodegree coursework.

This app is my first look into Core Data and how to use it to store remotely
fetched data. The app takes a location given by the user, fetches data and
images from Flickr relating to that location and finally stores it all using
Core Data.

I found this app somewhat easier than the previous one, On The Map, because
I was able to reuse much of the networking code from it. Now that I
understand closures and completion handlers better, the networking side of
this app was relatively straightforward.

Core Data presented some challenges, mainly in the areas of threading and
storage of unsupported data types. I learnt that you must only call a managed
object context on the thread which it is created on, otherwise you get weird
errors. I also learnt that Core Data doesn't really get along with some native
Swift data types like Array and Int, sometimes giving more weird errors and
other times simply refusing to work. So I used Objective-C data types where
needed in the Core Data managed objects, and cast them into Swift types in
code.

Overall, once I got the hang of the Core Data jargon actually using it
wasn't as scary as I thought it was before :)
