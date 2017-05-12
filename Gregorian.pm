package Calendar::Gregorian;

# Perl routines to translate Gregorian dates to and from Julian days.
# Aaron Mansheim, Sept 1996 (Tishri 5757)
# modernized Feb 2003

# divdown - utility:
# Divide integer $n by natural $m and round down to nearest integer.
# If changing to "use integer", remove calls to int() from this routine.

sub divdown {
  my ($n, $m) = @_;
  if ($n < 0) { return int($n/$m)-1; }
  else { return int($n/$m); }
}


# greg2jd - Translate Gregorian date to Julian days.
# &greg2jd( 1, 1, 2000) == 2451545
# &greg2jd(31,12, 1999) == 2451544
# &greg2jd( 7, 9,-3760) ==  347998 # year 0 == 1 BCE, -1 == 2 BCE, etc.

sub greg2jd {
  my ($day, $month, $year) = @_;
  my (@months, $i);
  my ($jd);
  my ($era, $century, $olympiad);

  @months = (31,28,31,30,31,30,31,31,30,31,30,31);
  $jd = 1721426; # Julian day for Greg. "1 Jan 1 CE"
  
  $year -= 1;
  $era = &divdown($year, 400); $year %= 400;
  $century = &divdown($year, 100); $year %= 100;
  $olympiad = &divdown($year, 4); $year %= 4;

  $jd += $era*146097 + $century*36524 + $olympiad*1461 + $year*365;

  if ( ($year == 3) && (!($olympiad == 24) || ($century == 3)) ) {
	$months[1] = 29;
	}
  for ($i=0; $i<$month-1; $i++) {
	$jd += $months[$i];
	}
  $jd += $day-1;
  return ($jd);
  }


# jd2greg - Translate Julian days to a Gregorian date. Inverts greg2jd.
# &jd2greg(2451545) == ( 1, 1, 2000)
# &jd2greg(2451544) == (31,12, 1999)
# &jd2greg( 347998) == ( 7, 9,-3760) # year 0 == 1 BCE, -1 == 2 BCE, etc.

sub jd2greg {
  my ($jd) = @_;
  my (@months, $epoch, $length);
  my ($day, $month, $year);
  my ($era, $century, $olympiad);

  #          JanFebMarAprMayJunJulAugSepOctNovDec
  @months = (31,28,31,30,31,30,31,31,30,31,30,31);

  $epoch = 1721426; # Julian day for Greg. "1 Jan 1 CE"
  $day = $jd - $epoch;
  
  $era = &divdown($day, 146097); $day %= 146097;

  if ($day == 146096) { $century = 3; $day = 36524; }
  else { $century = &divdown($day, 36524); $day %= 36524; }
    
  $olympiad = &divdown($day, 1461); $day %= 1461;
    
  if ($day == 1460) { $year = 3; $day = 365; }
  else { $year = &divdown($day, 365); $day %= 365; }

  if ( ($year == 3) && (!($olympiad == 24) || ($century == 3)) ) {
	$months[1] = 29;
	}

  for ($month = 0; $months[$month] <= $day; $month++) {
	$day -= $months[$month];
	}
  $month++;

  $year += 1; $day += 1;
  $year += 4*$olympiad + 100*$century + 400*$era;

  return ($day, $month, $year);
  }

1;
