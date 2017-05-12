I wrote this a very long time ago.

I revised it a long time after that. That was also a long time ago.

In case we want to use it, I just now worked out this example.

This prints the date of the first day (Rosh Hashanah) of the Hebrew year 5777, in ISO format (four-digit year, hyphen, two-digit month, hyphen, two-digit day):

    $ perl -MHebrew -MGregorian -e 'printf("%04d-%02d-%02d\n", reverse(Calendar::Gregorian::jd2greg(Calendar::Hebrew::Year::rosh(5777))))'
    2016-10-03
