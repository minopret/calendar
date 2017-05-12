package Calendar::Hebrew::Year;

# Hebrew calendar routines.

# Hebrew calendar theory.
# The Hebrew calendar fits lunar months within solar years by
# scheduling leap months in a 19-year cycle. A second adjustment 
# is made by adding up to two days to any year. To determine 
# this second adjustment, it is necessary to determine the 
# calculated date and time of the new moon which begins the 
# first month of the year, as well as of the new moon which
# ends the last month of the year.
#
# Days are considered to start at 6pm, sort of --
# actually, they start at sunset, and the time until sunrise is
# divided equally into 12 "hours"; there are also 12 daytime "hours".
# Julian days start at noon. We'll identify a Hebrew date with the 
# Julian day that includes the same afternoon.
#
# The time of a new moon is calculated in units of 1/1080 hour,
# called "parts" here. The time between new moons is 29.5 days plus
# 793 parts. The first new moon was 5 hours plus 204 parts into
# Julian day 347998, a Monday.


# THINGS USED INTERNALLY

sub date2 () { 347998; } # Julian day number for 2nd day of Creation
sub day2 () { 2; } # code for Monday, the 2nd day of the week
sub dayshift () { 2; } # defined by (&date2 + &dayshift) % 7 == &day2
sub lunation1 () { 5604; } # how many parts into that day the first new moon fell
sub ppd () { 25920; } # parts per day


# hebleap - test whether a Hebrew year is a leap year
sub hebleap {
  my ($year) = @_;

  # It's a leap year if it's congruent to one of these residues modulo 19:
  # 0, 3, 6       ( integers 0--7 congruent to 0 modulo 3 )
  # 8, 11, 14, 17 ( integers 8--18 congruent to 2 modulo 3 )

  $year %= 19;
  if ($year <= 7) { return ($year%3 == 0); }
  else { return ($year%3 == 2); }
  }

# END OF THINGS USED INTERNALLY


sub divdown {
  my ($n, $m) = @_;
  if ($n < 0) { return int($n/$m)-1; }
  else { return int($n/$m); }
}


# heblen2desc - given the length of a year, describe the year:
# 1. Is it a leap year? 2. How long is Heshvan? 3. How long is Kislev?
# note length should be one of 353,354,355, 383,384,385.
# It would be nice to use the official "character" of a year,
# a three-letter code specified thus:
# a) day of Rosh Hashanah: alef = Sunday, bet = Monday, etc.
# b) the initial of the "kind":
#  Heshvan+Kislev=58: chet stands for ChSRH, "defective"
#  Heshvan+Kislev=59: khaf stands for KhSIDRH, "regular"
#  Heshvan+Kislev=60: shin stands for ShLMH, "full"
# c) day of 15 Nisan, which depends on the first two codes
#  plus whether it's a leap year.
# There are 14 possible characters:
#     Leap years: ZShH ZChG HShG HChA GKhZ BShZ BChH
# Non-leap years: ZShG ZChA HShA HKhZ GKhH BShH BChG
# Numerically: 725 703 523 501 317 227 205  c = (a+b+2)%7+1
#              723 701 521 517 315 225 203  c = (a+b)%7+1
# Thus character abc implies a leap year if (a+b-c)%7 == 4
# and a non-leap year if (a+b-c)%7 == 6.
sub heblen2desc {
  my ($length) = @_;
  my ($leap, $kind);

  if ($length > 355) { $leap = 1; }
  else { $leap = 0; }
  $kind = $length - ($leap?383:353);
  return (leap=>$leap, kind=>$kind);
  }


# rosh - find the Julian day of Rosh Hashanah for a specified Hebrew year.
# &rosh(   1) ==  347998
# &rosh(5757) == 2450341
# Would be nice to break out the finding of the new moon for a month
# as a separate routine.

sub rosh {
  my($year) = @_;
  my(@leap, $months, $cycles, $cycleyear, $leaps);
  my($date, $parts, $day);
  my($rhdate, $rhday);

  # Cycles are 1--19, 20--38, etc.
  $cycles = &divdown($year-1, 19);
  $cycleyear = ($year-1)%19;

  # How many leap years in this cycle, before this year?
  #        *        *     *        *        *        *     *
  #  0  1  2  3  4  5  6  7  8  9 10 11 12 13 14 15 16 17 18 19
  #  0  0  0  1  1  1  2  2  3  3  3  4  4  4  5  5  5  6  6  7
  # See hebleap for details.
  if ($cycleyear <= 7) { $leaps = &divdown($cycleyear, 3); }
  elsif ($cycleyear == 19) { $leaps = 7; }
  else { $leaps = &divdown($cycleyear+1, 3); }

  # How many months from Creation to this year?
  # 235 == 19 years * 12 months/year + 7 leap months
  $months = $cycles*235 + $cycleyear*12 + $leaps;

  # What are the date and time of the new moon beginning this year?
  # Be slightly careful not to use too many significant digits,
  # to avoid incorrect results from the modulus operator (%).
  $date = &date2 + $months * 29 + &divdown($months, 2);
  $parts = $months*793 + &lunation1 + ($months%2)*&ppd/2;
  $date += &divdown($parts, &ppd);
  $parts = $parts % &ppd;
  $day = ($date+&dayshift) % 7;


  # Compute date of Rosh Hashanah (first day of the year)

  # We'll keep track of the day of the week of Rosh Hashanah
  # separately for reasons of clarity, convenience, and completeness,
  # but we won't actually need to. The caller can get that info
  # from the (Julian day + 2) % 7.

  $rhdate = $date;
  $rhday = $day;

  if (($rhday == 1) || ($rhday == 4) || ($rhday == 6)) {
    # lunation on Sunday, Wednesday, or Friday:
    # Keep Yom Kippur (10 Tishri) from falling on Friday or Sunday
    # and Hoshanna Rabbah (21 Tishri) from falling on Shabbat.
    $rhday = ($rhday+1)%7; $rhdate += 1;
    }
  elsif ($parts >= 19440) { # lunation at or after noon:
    # Start the year when the new moon is calculated to be actually visible.
    $rhday = ($rhday+1)%7; $rhdate += 1;
    if (($rhday == 1) || ($rhday == 4) || ($rhday == 6)) {
      $rhday = ($rhday+1)%7; $rhdate += 1;
      }
    }
  elsif (($rhday == 3) && !&hebleap($year) && ($parts >= 9924)) {
    # lunation Tues at or after 3 AM + 204 parts, in non-leap year:
    # Keep this year from being too long (> 355 days).
    $rhday = ($rhday+2)%7; $rhdate += 2;
    }
  elsif (($rhday == 2) && &hebleap($year-1) && ($parts >= 16789)) {
    # lunation Mon at or after 9 AM + 589 parts, following leap year:
    # Keep previous year from being too short (< 383 days).
    $rhday = ($rhday+1)%7; $rhdate += 1;
    }

  return $rhdate;
  }



package Calendar::Hebrew;

# Hebrew calendar routines
# Aaron Mansheim, Sept 1996 (Tishri 5757)
# modernized Feb 2003

#use Calendar::Hebrew::Year;

# jd2heb - Translate Julian days into a Hebrew date.
# &jd2heb(2450341) == (1,1,5757) # Rosh Hashanah
# &jd2heb(2450531) == (14,6,5757) # Purim, 14 Adar

sub jd2heb {
  my ($jd, $rest) = @_;
  my ($epoch);
  my ($cycles, $cycleyear, $months, $year);
  my ($start, $end);
  my (@desc);
  my ($day,$month);

  $epoch = 347998;
  $jd -= $epoch;

  # Take a stab at which year it might be.
  # 19 years == 235 lunations == about 235*29.53059 days == 6939.7 days.
  $cycles = &divdown($jd,6940);
  $rest = $jd % 6940;
  $months = int($rest/29.53059);
  $cycleyear = int($months*19/235);
  $year = $cycles*19 + $cycleyear + 1;
  $start = &Calendar::Hebrew::Year::rosh($year) - $epoch;

  # Do a linear search to bracket the jd with Rosh Hashanah dates.
  # This is easy to write, although in practice we hardly need it.
  # That's good, because it's inefficient.
  if ($start > $jd) { # $year is too high 
	while ($start > $jd) {
	  $year--;
	  $end = $start;
	  $start = &Calendar::Hebrew::Year::rosh($year) - $epoch;
	  }
	}
  else { # $year may not be high enough
	$end = &Calendar::Hebrew::Year::rosh($year+1) - $epoch;
	while ($end <= $jd) {
	  $year++;
	  $start = $end;
	  $end = &Calendar::Hebrew::Year::rosh($year+1) - $epoch;
	  }
	}
  # $year is now correct.

  %desc = &heblen2desc($end - $start);

  #           1  2  3  4  5  6  7  8  9 10 11 12
  #          TisHesKisTevSheAdaNisIyaSivTamAv Elu
  @months = (30,29,30,29,30,29,30,29,30,29,30,29);

  $day = $jd - $start;

  if ($desc{kind} == 0) { $months[2] = 29; }
  elsif ($desc{kind} == 2) { $months[1] = 30; }

  # This block is ad hoc and it shows.
  if ($desc{leap}) {
	if ($day >= 177 + $desc{kind}) {
	  #given day is after Adar I
	  $day -= 30;
	  }
	elsif ($day >= 147 + $desc{kind}) {
	  # given day is during Adar I
	  $month = 13; $day -= 146 + $desc{kind};
	  return ($day, $month, $year);
	  }
	}

  for ($month=0; $months[$month] <= $day; $month++) {
	$day -= $months[$month];
	}
  $day += 1; $month += 1;

  return ($day,$month,$year);
  }


# heb2jd - Translate a Hebrew date into Julian days. Inverts jd2heb.
# &heb2jd(1,1,5757) == 2450341 # Rosh Hashanah
# &heb2jd(14,6,5757) == 2450531 # Purim, 14 Adar
# Adar == Adar II; Adar I is month 13 and interpolates between months 5 and 6.
# (Adar and Adar II have same length; holidays are in Adar II in leap years)

sub heb2jd {
  my ($day, $month, $year) = @_;
  my ($jd, $end, $kind, $i);

  #           1  2  3  4  5  6  7  8  9 10 11 12
  #          TisHesKisTevSheAdaNisIyaSivTamAv Elu
  @months = (30,29,30,29,30,29,30,29,30,29,30,29);

  $jd = &Calendar::Hebrew::Year::rosh($year);
  $end = &Calendar::Hebrew::Year::rosh($year+1);
  if ($end-$jd > 356) { $leap = 1; }
  else { $leap = 0; }
  $kind = $end-$jd-353-$leap*30;
  if ($kind == 0) { $months[2] = 29; }
  elsif ($kind == 2) { $months[1] = 30; }

  # This block is ad hoc and it shows.
  if ($leap && ($month > 5)) {
	if ($month == 13) { 
	  if ($day == 30) { 
		return ($jd + $kind + 176); 
		} 
	  else { $month = 6; }
	  }
	else { 
	  $jd += 30;
	  }
	}

  for ($i=0; $i<$month-1; $i++) {
	$jd += $months[$i];
	}
  $jd += $day-1;

  return $jd;
  }

1;