/*
 *  The scanner definition for COOL.
 */

/*
 *  Stuff enclosed in %{ %} in the first section is copied verbatim to the
 *  output, so headers and global definitions are placed here to be visible
 * to the code in the file.  Don't remove anything that was here initially
 */

%option noyywrap

%{
#include <cool-parse.h>
#include <stringtab.h>
#include <utilities.h>
#include <vector>

/* The compiler assumes these identifiers. */
#define yylval cool_yylval
#define yylex  cool_yylex

/* Max size of string constants */
#define MAX_STR_CONST 1025
#define YY_NO_UNPUT   /* keep g++ happy */

extern FILE *fin; /* we read from this file */

/* define YY_INPUT so we read from the FILE fin:
 * This change makes it possible to use this scanner in
 * the Cool compiler.
 */
#undef YY_INPUT
#define YY_INPUT(buf,result,max_size) \
	if ( (result = fread( (char*)buf, sizeof(char), max_size, fin)) < 0) \
		YY_FATAL_ERROR( "read() in flex scanner failed");

char string_buf[MAX_STR_CONST]; /* to assemble string constants */
char *string_buf_ptr;

extern int curr_lineno;
extern int verbose_flag;

extern YYSTYPE cool_yylval;

/*
 *  Add Your own definitions here
 */
static int commentCaller;
static int stringCaller;
static std::vector<char> stringArray;
%}

/*
 * Define names for regular expressions here.
 */

DARROW          =>
ASSIGN          <-
LE              <=
CLASS           class
ELSE            else
FI              fi
IF              if
IN              in
INHERITS        inherits
LET             let
LOOP            loop
POOL            pool
THEN            then
WHILE           while
CASE            case
ESAC            esac
OF              of
NEW             new
ISVOID          isvoid
NOT             not

%x COMMENT
%x STRING
%x STRING_ESCAPE

%%

 /*
  *  comments
  */
--.*$ {}
"(*" {
  commentCaller = INITIAL;
  BEGIN(COMMENT);
}
<COMMENT>"*)" {
  BEGIN(commentCaller);
}

<COMMENT>[^(\*\))] {
    if (yytext[0] == '\n') {
        ++curr_lineno;
    }
}

<COMMENT><<EOF>> {
    BEGIN(commentCaller);
    cool_yylval.error_msg = "EOF in comment";
    return (ERROR);
}

\*\) {
    cool_yylval.error_msg = "Unmatched *)";
    return (ERROR);
}

 /*
  *  The multiple-character operators.
  */
{DARROW} { return (DARROW); }
{ASSIGN} { return (ASSIGN); }
{LE} { return (LE); }

 /*
  * Keywords are case-insensitive except for the values true and false,
  * which must begin with a lower-case letter.
  */
{CLASS} { return (CLASS); }
{ELSE} { return (ELSE); }
{FI} { return (FI); }
{IF} { return (IF); }
{IN} { return (IN); }
{INHERITS} { return (INHERITS); }
{LET} { return (LET); }
{LOOP} { return (LOOP); }
{POOL} { return (POOL); }
{THEN} { return (THEN); }
{WHILE} { return (WHILE); }
{CASE} { return (CASE); }
{ESAC} { return (ESAC); }
{OF} { return (OF); }
{NEW} { return (NEW); }
{ISVOID} { return (ISVOID); }
{NOT} { return (NOT); }

 /*
  *  variables
  */
t[Rr][Uu][Ee] {
  cool_yylval.boolean = true;
  return (BOOL_CONST);
}

f[Aa][Ll][Ss][Ee] {
  cool_yylval.boolean = false;
  return (BOOL_CONST);
}

[A-Z_][A-Za-z0-9_]*  {
  cool_yylval.symbol = idtable.add_string(yytext, yyleng);
  return (TYPEID);
}

[a-z_][A-Za-z0-9_]*  {
  cool_yylval.symbol = idtable.add_string(yytext, yyleng);
  return (OBJECTID);
}

 /*
  * literal
  */

[0-9][0-9]* {
  cool_yylval.symbol = inttable.add_string(yytext, yyleng);
  return (INT_CONST);
}

 /*
  *  String constants (C syntax)
  *  Escape sequence \c is accepted for all characters c. Except for 
  *  \n \t \b \f, the result is c.
  *
  */

\" {
    stringCaller = INITIAL;
    stringArray.clear();
    BEGIN(STRING);
}

<STRING>[^\"\\]*\" {
    // push back string
    // does not include the last character \"
    stringArray.insert(stringArray.end(), yytext, yytext + yyleng - 1);
    // setup string table
    cool_yylval.symbol = stringtable.add_string(&stringArray[0], stringArray.size());
    // exit
    BEGIN(stringCaller);
    return (STR_CONST);
}

<STRING>[^\"\\]*\\ {
    // does not include the last character escape
    stringArray.insert(stringArray.end(), yytext, yytext + yyleng - 1);
    BEGIN(STRING_ESCAPE);
}

<STRING_ESCAPE>n {
    stringArray.push_back('\n');
    BEGIN(STRING);
}

<STRING_ESCAPE>b {
    stringArray.push_back('\b');
    BEGIN(STRING);
}

<STRING_ESCAPE>t {
    stringArray.push_back('\t');
    BEGIN(STRING);
}

<STRING_ESCAPE>f {
    stringArray.push_back('\f');
    BEGIN(STRING);
}

<STRING_ESCAPE>. {
    stringArray.push_back(yytext[0]);
    BEGIN(STRING);
}

<STRING_ESCAPE>\n {
    stringArray.push_back('\n');
    ++curr_lineno;
    BEGIN(STRING);
}

<STRING_ESCAPE>0 {
    cool_yylval.error_msg = "String contains null character";
    BEGIN(STRING);
    return (ERROR);
}

<STRING>[^\"\\]*$ {
    // push first
    // contains the last character for yytext does not include \n
    stringArray.insert(stringArray.end(), yytext, yytext + yyleng);
    //setup error later
    cool_yylval.error_msg = "Unterminated string constant";
    BEGIN(stringCaller);
    ++curr_lineno;
    return (ERROR);
}

<STRING_ESCAPE><<EOF>> {
    cool_yylval.error_msg = "EOF in string constant";
    BEGIN(STRING);
    return (ERROR);
}
<STRING><<EOF>> {
    cool_yylval.error_msg = "EOF in string constant";
    BEGIN(stringCaller);
    return (ERROR);
}

 /*
  * illegal
  */
[\[\]\'>] {
    cool_yylval.error_msg = yytext;
    return (ERROR);
}

\n { ++curr_lineno; }
[ \t\f\r\v]  {}

 /*
  * legal
  */
. { return yytext[0]; }

%%
