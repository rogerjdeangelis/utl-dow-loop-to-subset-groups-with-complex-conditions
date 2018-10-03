# utl-dow-loop-to-subset-groups-with-complex-conditions
DOW loop to subset groups with complex conditions.
    DOW loop to subset groups with complex conditions

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


