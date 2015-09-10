# modifier
------
During support we sometimes write some quickfix solutions, which we think will not be needed apart from that one time task. Thus the code usually has no tests, is not documented and just everything in one large file. Attached you find an example for such an assumed one time task - modifier.rb.

I'd like you to do the following:
- give me a short explanation of what the code actually does.
- refactor the code and ensure that the refactored code does the same
  as before.
- create a git repository containing the initial files and do regular
  and small commits to log your process.
- send me your git bundle containing your changes.
------

EXPLANATION: I believe the modifier recevies an input CSV file with the
intention to transform it into a new CSV file, but modified by certain rules.
It combines several CSV files into one file. The KEYWORD_UNIQUE_ID helps the
modifier to merge the rows however it has to handle multiple values coming from
each row which is where the combiner helps out.