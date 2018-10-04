DOW loop to subset groups with complex conditions

Recent Thread on end

1. Mark Keintz Wharton
2. Bartosz Jablonski gmail
3. Quentin McMullin Large Pharma

see github
https://tinyurl.com/ybd392ab
https://github.com/rogerjdeangelis/utl-dow-loop-to-subset-groups-with-complex-conditions

see SAS Forum
https://tinyurl.com/ycwg9wj3
https://communities.sas.com/t5/SAS-Programming/Flagging-based-on-two-criteria-within-specific-period/m-p/501061

Subset patient groups using

   1. Have two dx='666' occurring with one year
   2. OR have one dx='666' and one dx='250' within one year


INPUT
=====

 WORK.HAVE total obs=7                         | RULES
                                               |
  PATIENTID  YEAR    DX1    DX2    DX3    DX4  |
                                               |
      1      2009    250    223    224    444  | has condition 2
      1      2009    555    666    120    290  | one 666 and one 250

      2      2007    120    666    120    290  |
      2      2007    120    666    120    290  | has condition 1 two 666s

      3      2004    250    120    290    120  |
      3      2004    240    250    120    290  |
      3      2004    250    120    290    120  | Does not have either condition


EXAMPLE OUTPUT
--------------

 WORK.WANT total obs=4

  PATIENTID    YEAR    DX1    DX2    DX3    DX4    SUM_666    SUM_250

      1        2009    250    223    224    444       1          1
      1        2009    555    666    120    290       1          1
      2        2007    120    666    120    290       2          0
      2        2007    120    666    120    290       2          0


PROCESS
=======

data want;

  do until(last.year);
     set have;
     by patientid year;
     sum_666 + (dx1=666)+(dx2=666)+(dx3=666);  * for critical sums;
     sum_250 + (dx1=250)+(dx2=250)+(dx3=250);
  end;

  do until(last.year);
     set have;
     by patientid year;
     if  sum_666=2 or ( sum_666=1 and  sum_250=1) then output;
  end;

  sum_666 =0 ;
  sum_250 =0 ;

run;quit;

OUTPUT
======

 see above

*                _               _       _
 _ __ ___   __ _| | _____     __| | __ _| |_ __ _
| '_ ` _ \ / _` | |/ / _ \   / _` |/ _` | __/ _` |
| | | | | | (_| |   <  __/  | (_| | (_| | || (_| |
|_| |_| |_|\__,_|_|\_\___|   \__,_|\__,_|\__\__,_|

;

DATA HAVE;
  retain patientid year;
  INPUT patientid 1-2 dx1 3-5 dx2 7-9 dx3 11-13 dx4 15-17 date mmddyy10.;
  year=year(date);
  format date mmddyy10.;
  drop date;
cards4;
1 250 223 224 444 5/5/2009
1 555 666 120 290 10/6/2009
2 120 666 120 290 1/2/2007
2 120 666 120 290 1/1/2007
3 250 120 290 120 2/2/2004
3 240 250 120 290 3/3/2004
3 250 120 290 120 1/1/2004
;;;;
run;quit;


*__  __            _
|  \/  | __ _ _ __| | __
| |\/| |/ _` | '__| |/ /
| |  | | (_| | |  |   <
|_|  |_|\__,_|_|  |_|\_\

;

Keintz, Mark
mkeintz@wharton.upenn.edu


Roger et. al.

Recently I've been trying to moderate my atavistic impulse to use double DOW's.
So, instead of two "do until ..." loops, this code uses a single loop,
but names the incoming data set twice in the set statement.

DATA HAVE;
  retain patientid year;
  INPUT patientid 1-2 dx1 3-5 dx2 7-9 dx3 11-13 dx4 15-17 date mmddyy10.;
  year=year(date);
  format date mmddyy10.;
  drop date;
cards;
1 250 223 224 444 5/5/2009
1 555 666 120 290 10/6/2009
2 120 666 120 290 1/2/2007
2 120 666 120 290 1/1/2007
3 250 120 290 120 2/2/2004
3 240 250 120 290 3/3/2004
3 250 120 290 120 1/1/2004
run;

data want (drop=_:);
 do until (last.year);
   set have (in=pass1) have (in=pass2);
   by patientid year;
   if pass1 then do;
     _n666=sum(_n666,count(catx(' ',of dx:),'666'));
     _n250=sum(_n250,count(catx(' ',of dx:),'250'));
   end;
   if pass2 and (_n666=2 or (_n666=1 and _n250=1)) then output;
  end;
run;

Instead of iteratively looking at dx1,dx2,dx3 for 666 and 250, you
might like the COUNT(catx ...) approach - much more concise when
there is a long list of variables.  If there is the possibility of
4 digit numbers containing the special values, then put sentinels
('x' values) at the ends of the catx arguments, and use a non-blank separator:

     _n666=sum(_n666,count(catx('_','x',of dx:,'x'),'_666_'));
     _n250=sum(_n250,count(catx('_','x',of dx:,'x'),'_250_'));

Regards,
Mark


*____             _
| __ )  __ _ _ __| |_
|  _ \ / _` | '__| __|
| |_) | (_| | |  | |_
|____/ \__,_|_|   \__|

;

Bartosz Jablonski
yabwon@gmail.com


Hi Mark,

your mail and code inspired me to play with the code and I want to
share one more version of possible solution (with only one data reading).

thanks!
Bart

/* code */
data wantHash(drop=_:);

/* container for data */
if _N_=1 then do;
    declare hash H(dataset: "have(obs=0)", multidata:'y');
    _I_ = H.DefineKey("patientid","year");
    _I_ = H.DefineData(all: 'yes');
    _I_ = H.DefineDone();
end;

/* clear */
_I_ = H.Clear();
_n666=0;
_n250=0;

do until (last.year);
    set have end=EOF;
    by patientid year;

    /* populate */
     _I_ = H.Add();
     _n666=sum(_n666,count(catx(' ',of dx:),'666'));
     _n250=sum(_n250,count(catx(' ',of dx:),'250'));
end;

/* verify condition and output */
if (_n666=2 or (_n666=1 and _n250=1)) then
do;
    /*put _N_= patientid= year= _n666= _n250=;*/
    _I_ = H.RESET_DUP();
    do while(H.DO_OVER() eq 0);
        output;
    end;
end;

if EOF then stop;
run;

* ___                   _   _
 / _ \ _   _  ___ _ __ | |_(_)_ __
| | | | | | |/ _ \ '_ \| __| | '_ \
| |_| | |_| |  __/ | | | |_| | | | |
 \__\_\\__,_|\___|_| |_|\__|_|_| |_|

;

That's nifty, Bart.

Is H.ResetDup() needed here?  I hadn't seen it before, but I looked it up,
and I think it would only be needed if h.do_over() was not reading the
full group of duplicate records for a key.

So, for example, if the requirement were "output the first three records
for each patient-year where ..." and there were some cases
with more than 3 records, you might code:

do i=1 to 3 while(H.DO_OVER() eq 0);
  output;
end;

In that case I think you would need to use RESET_DUP() because
if there were more than 3 records in a group, you need RESET_DUP()
tell DO_OVER to look for a new key rather than continue
with the group it's currently iterating through.

BTW, in reading the docs on ResetDup(), I noticed that the only example
they give doesn't actually require ResetDup, nor does
ResetDup have any impact, for the same reason.  Their example is:

data dup;
   input key_id value;
   datalines;
   1 10
   2 11
   1 15
   3 20
   2 16
   2 9
   3 100
   5 5
   1 5
   4 6
   5 99
;
run;

data _null_;
   dcl hash h(dataset:'dup', multidata: 'y', ordered: 'y');
   h.definekey('key_id');
   h.definedata('key_id', 'value');
   h.definedone();
   call missing(key_id, value);

   h.reset_dup();  *This reset_dup call does nothing ! ? ! ;
   key_id = 2;
   do while(h.do_over(key:key_id) eq 0);
      put key_id= value=;
   end;

   key_id = 3;
   do while(h.do_over(key:key_id) eq 0);
      put key_id= value=;
   end;

   key_id = 2;
   do while(h.do_over(key:key_id) eq 0);
     put key_id= value=;
   end;
run;

https://tinyurl.com/ycfp3fot
https://documentation.sas.com/?docsetId=lecompobjref&docsetTarget=p07odyzmifa4y3n10pkcvfdbtn4l.htm&docsetVersion=9.4&locale=en#n1mu8u0wwz34e4n15ko5shg9fhjm


Kind Regards,
--Q.

*____             _
| __ )  __ _ _ __| |_ ___  ___ ____
|  _ \ / _` | '__| __/ _ \/ __|_  /
| |_) | (_| | |  | || (_) \__ \/ /
|____/ \__,_|_|   \__\___/|___/___|

;

Bartosz Jablonski via listserv.uga.edu
9:49 AM (1 hour ago)
to SAS-L

Hi Quentin,

good point, you're right. H.Rest_Dup() is not necessary I used it "just in case" and out of habit :-)

Saying about example of Rest_Dup() usage, I think that my previous post in thread: "SAS-L:
Using modify to conserve disk space when removing duplicates" is good example that it is
good to have RestDup(). I'm looping there several times through one key
(but once again, "just in case", I'm using Rest_Dup before all Do_Overs - hmmm... Am I getting paranoiac? :-D :-D).

all the best
Bart

P.S. Is it just my "Polish grumbling" or the older versions of the doc.
were better prepared? ;-) I think we can offer to SAS another/better example for the doc

/*example*/
data A;
input k d;
cards;
1 1
1 2
1 3
1 4
1 5
;
run;

data No_Reset_Dup;

if 0 then set A;
declare hash H(dataset:'a', multidata: "Y");
H.definekey('K');
H.definedata("D");
H.definedone();

k=1;
do i=1 to 3 while(H.DO_OVER() eq 0);
  put "1)" _ALL_; output;
end;

_N_=.; /* no Reset_Dup() here */
k=1;
do i=1 to 3 while(H.DO_OVER() eq 0);
  put "2)" _ALL_; output;
end;

stop;
run;

data Reset_Dup;

if 0 then set A;
declare hash H(dataset:'a', multidata: "Y");
H.definekey('K');
H.definedata("D");
H.definedone();

k=1;
do i=1 to 3 while(H.DO_OVER() eq 0);
  put "1)" _ALL_; output;
end;

_N_=H.Reset_Dup();
k=1;
do i=1 to 3 while(H.DO_OVER() eq 0);
  put "2)" _ALL_; output;
end;

stop;
run;

* ___                   _   _
 / _ \ _   _  ___ _ __ | |_(_)_ __
| | | | | | |/ _ \ '_ \| __| | '_ \
| |_| | |_| |  __/ | | | |_| | | | |
 \__\_\\__,_|\___|_| |_|\__|_|_| |_|

;

Quentin McMullen via listserv.uga.edu
11:07 AM (12 minutes ago)
 to SAS-L

Hi,

Yes, if looping  through same key group multiple times, would definitely need ResetDup().

I think for the docs, I would suggest an example where there are two groups, and the
Do_Over() user might naively think that if they change the key, Do_Over would look for
the new key instead of continue within the old key group.

Something like:

/*example*/
data A;
input k d;
cards;
1 1
1 2
1 3
1 4
2 5
2 6
2 7
2 8
;
run;

data No_Reset_Dup;

if 0 then set A;
declare hash H(dataset:'a', multidata: "Y");
H.definekey('K');
H.definedata("D");
H.definedone();

k=1;
do i=1 to 3 while(H.DO_OVER() eq 0);
  put "1)" _ALL_; output;
end;

_N_=.; /* no Reset_Dup() here */
k=2;
do i=1 to 3 while(H.DO_OVER() eq 0);
  put "2)" _ALL_; output;
end;

stop;
run;

data Reset_Dup;

if 0 then set A;
declare hash H(dataset:'a', multidata: "Y");
H.definekey('K');
H.definedata("D");
H.definedone();

k=1;
do i=1 to 3 while(H.DO_OVER() eq 0);
  put "1)" _ALL_; output;
end;

_N_=H.Reset_Dup();
k=2;
do i=1 to 3 while(H.DO_OVER() eq 0);
  put "2)" _ALL_; output;
end;

stop;
run;


Or maybe simpler:

data _null_;
if 0 then set A;
declare hash H(dataset:'a', multidata: "Y");
H.definekey('K');
H.definedata("K","D");
H.definedone();

H.DO_OVER(key:1) ;
put "DO_OVER(key:1): " (_all_)(=) ;
H.DO_OVER(key:1) ;
put "DO_OVER(key:1): " (_all_)(=) ;

*no reset_dup, so do_over continues reading key=1 group despite being called with key=2!!! ;
H.DO_OVER(key:2) ;
put "DO_OVER(key:2) without reset_dup: " (_all_)(=) ;
H.DO_OVER(key:2) ;
put "DO_OVER(key:2) without reset_dup: " (_all_)(=) ;

H.Reset_Dup() ; *reset_dup moves pointer out of the key=1 group, so next call to do_over will find a new key group;

H.DO_OVER(key:2) ;
put "DO_OVER(key:2) after reset_dup: "(_all_)(=) ;
H.DO_OVER(key:2) ;
put "DO_OVER(key:2) after reset_dup: "(_all_)(=) ;

stop ;
run ;

Returns:
DO_OVER(key:1): k=1 d=1
DO_OVER(key:1): k=1 d=2
DO_OVER(key:2) without reset_dup: k=1 d=3
DO_OVER(key:2) without reset_dup: k=1 d=4
DO_OVER(key:2) after reset_dup: k=2 d=5
DO_OVER(key:2) after reset_dup: k=2 d=6

Thanks again for introducing me to Reset_Dup!

Kind Regards,
-Q.




