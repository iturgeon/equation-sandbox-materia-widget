{
	var variables = {};
	var mainVar = null;
	var mainExpr = "";

	function jsVariableToLatexString(jsVariableName)
	{
		var ls = jsVariableName
			.replace(/\$backslash_/g, '\\')
			.replace(/\$prime_/g, "'")
			.replace(/\$leftBracket_/g, '{')
			.replace(/\$rightBracket_/g, '}')
			.replace(/\$caret_/g, '^')
			.replace(/\$plus_/g, '+')
			.replace(/\$minus_/g, '-')
			.replace(/\$times_/g, '\\cdot')
			.replace(/\$divide_/g, '\\div')
			.replace(/\$exponent_/g, '^');

		return ls;

	}

	function getVarObj(jsVariableName)
	{
		var latexVariableString = jsVariableToLatexString(jsVariableName);
		return {
			js: jsVariableName,
			latex: latexVariableString
		};
	}

	function registerVar(jsVariableName)
	{
		variables[jsVariableName] = getVarObj(jsVariableName);
	}

	function getSymbolName(symbol)
	{
		switch(symbol)
		{
			case "+": return "plus";
			case "-": return "minus";
			case "*":
			case "\\times":
			case "\\cdot":
				return "times";
			case "/":
			case "\\div":
				return "divide";
			case "^": return "exponent";
		}
	}
}

start
	= eq:equation {
		var vars = [];
		var jsVars = [];

		for(var k in variables)
		{
			if(mainVar.js === k) throw("Left-hand side variable " + k + " cannot appear in right-hand side expression.");

			vars.push(variables[k]);
			jsVars.push(k);
		}

		return {
			variables: vars,
			mainVar:   mainVar,
			mainExpr:  mainExpr,
			fn:        new Function(jsVars, 'return ' + mainExpr + ';')
		};
	}

equation
	= lhs:lhsString s* "=" s* rhs:expr {
		mainVar = lhs; //getVarObj(lhs);
		mainExpr = rhs;
		return lhs + "=" + rhs;
	}

lhsString
	= s:[^=]+ { return s.join(""); }

expr
	= "-" expr:symbolicExpr { return "-" + expr }
	/ symbolicExpr
	/ "-" expr:nonSymbolicExpr { return "-" + expr }
	/ nonSymbolicExpr

nonSymbolicExpr
	= unaryExpr
	/ fracExpr
	/ binomExpr
	/ parentheticalMultiplicativeExpr
	/ assumedMultiplicativeExpr
	/ functionExpr
	/ nonBracketedFunctionExpr
	/ bracketedExpr
	/ value

fn
	= "\\sqrt" { return "Math.sqrt" }
	/ fnThatDoNotRequireBrackets

fnThatDoNotRequireBrackets
	= "\\arcsin" { return "Math.asin"; }
	/ "\\arccos" { return "Math.acos"; }
	/ "\\arctan" { return "Math.atan"; }
	/ "\\sinh"   { return "Math.sinh"; }
	/ "\\cosh"   { return "Math.cosh"; }
	/ "\\tanh"   { return "Math.tanh"; }
	/ "\\sin"    { return "Math.sin"; }
	/ "\\cos"    { return "Math.cos"; }
	/ "\\tan"    { return "Math.tan"; }
	/ "\\sec"    { return "Math.sec"; }
	/ "\\csc"    { return "Math.csc"; }

parentheticalMultiplicativeExpr
	= lhs:bracketedExpr rhs:bracketedExpr+ { return lhs + "*" + rhs.join("*"); }
	/ lhs:value rhs:bracketedExpr+ { return lhs + "*" + rhs.join("*"); }
	/ lhs:bracketedExpr+ rhs:value { return lhs.join("*") + "*" + rhs; }

assumedMultiplicativeExpr
	= expr:nonSymbolicExpr_excludingAssumedMultiplicativeExpr exprs:nonSymbolicExpr+ { return expr + "*" + exprs.join("*"); }

nonSymbolicExpr_excludingAssumedMultiplicativeExpr
	= unaryExpr
	/ fracExpr
	/ binomExpr
	/ parentheticalMultiplicativeExpr
	/ functionExpr
	/ nonBracketedFunctionExpr
	/ bracketedExpr
	/ value


fracExpr
	= "\\frac{" lhs:expr "}{" rhs:expr "}" { return "(" + lhs + ")/(" + rhs + ")"; }

binomExpr
	= "\\binom{" top:expr "}{" bottom:expr "}" { return "Math.binom(" + top + "," + bottom + ")"; }

bracketedExpr
	= leftBracket s* expr:expr s* rightBracket { return "(" + expr + ")"; }

nonBracketedFunctionExpr
	= fn:fnThatDoNotRequireBrackets expr:nonSymbolicExpr { return fn + "(" + expr + ")"; }
	/ fn:fnThatDoNotRequireBrackets s+ expr:exponentialExpr { return fn + "(" + expr + ")"; }
	/ fn:fnThatDoNotRequireBrackets n:numericValue { return fn + "(" + n + ")"; }
	/ fn:fnThatDoNotRequireBrackets s+ v:value { return fn + "(" + v + ")"; }


functionExpr
	= fn:fn expr:bracketedExpr { return fn + expr; }

operator
	= "-"
	/ "+"
	/ "*"
	/ "/"
	/ "\\times" { return "*" }
	/ "\\cdot" { return "*" }
	/ "\\div" { return "/" }

leftBracket
	= "\\left(" { return "("; }
	/ "\\left[" { return "("; }
	/ "\\left{" { return "("; }
	/ "\\{"     { return "("; }
	/ "("       { return "("; }
	/ "["       { return "("; }
	/ "{"       { return "("; }

rightBracket
	= "\\right)" { return ")"; }
	/ "\\right]" { return ")"; }
	/ "\\right}" { return ")"; }
	/ "\\}"      { return ")"; }
	/ ")"        { return ")"; }
	/ "]"        { return ")"; }
	/ "}"        { return ")"; }

symbolicExpr
	= exp:exponentialExpr rest:restSymbolicExpr* { return exp + rest.join("");}
	/ lhs:nonSymbolicExpr rhs:restSymbolicExpr* { return lhs + rhs.join(""); }

exponentialExpr
	= lhs:nonSymbolicExpr "^{" s* rhs:symbolicExpr s* "}" { return "Math.pow(" + lhs + "," + rhs + ")"; }
	/ lhs:nonSymbolicExpr "^" val:value { return "Math.pow(" + lhs + "," + val + ")"; }

restSymbolicExpr
	= s* operator:operator s* rhs:expr { return operator + rhs; }

unaryExpr
	= v:value "!" { return "Math.factorial(" + v + ")"; }

value
	= numericValue
	/ v:subscriptedVariable  { registerVar(v); return v; }
	/ v:variable { registerVar(v); return v; }

subscriptedVariable
	= v:variable "_{" sub:subscript "}" { return v + "_$leftBracket_" + sub + "$rightBracket_"; }
	/ v:variable "_" sub:subValue { return v + "_" + sub; }
	/ v:variable

subscript
	= v:variable op:operator val:subValue { return v + "$" + getSymbolName(op) + "_" + val; }
	/ v:variable "^{" sub:subscript "}" { return v + "$caret_$leftBracket_" + sub + "$rightBracket_"; }
	/ v:variable "^" val:subValue { return v + "$caret_" + val; }
	/ val:subValue

subValue
	= numericValue
	/ subscriptedVariable
	/ variable




latexDefinedVariable
	= v:latexVar { return v.replace("\\", "$backslash_"); }

latexVar
	= "\\alpha"
	/ "\\beta"
	/ "\\Gamma"
	/ "\\gamma"
	/ "\\Delta"
	/ "\\delta"
	/ "\\epsilon"
	/ "\\varepsilon"
	/ "\\zeta"
	/ "\\eta"
	/ "\\Theta"
	/ "\\theta"
	/ "\\vartheta"
	/ "\\iota"
	/ "\\kappa"
	/ "\\varkappa"
	/ "\\Lambda"
	/ "\\lambda"
	/ "\\mu"
	/ "\\nu"
	/ "\\Xi"
	/ "\\xi"
	/ "\\omicron"
	/ "\\rho"
	/ "\\varrho"
	/ "\\Sigma"
	/ "\\sigma"
	/ "\\varsigma"
	/ "\\tau"
	/ "\\Upsilon"
	/ "\\upsilon"
	/ "\\Phi"
	/ "\\phi"
	/ "\\varphi"
	/ "\\chi"
	/ "\\Psi"
	/ "\\Omega"
	/ "\\omega"

variable
	= variable:latexDefinedVariable
	/ variable:customVariable

customVariable
	= v:[a-zA-Z] primes:"'"+ { return v + primes.map(function(p) { return '$prime_'; }).join(""); }
	/ [a-zA-Z]

numericValue
	= latexDefinedValue
	/ float
	/ int

latexDefinedValue
	= "\\infty" { return "Infinity"; }
	/ "\\Pi" { return "Math.PI"; }
	/ "\\pi" { return "Math.PI"; }
	/ "\\varpi" { return "Math.PI"; }
	/ "e" { return "Math.E"; }

float
	= left:[0-9]* "." right:[0-9]+ { return left.join("") + '.' + right.join(""); }

int
	= digits:[0-9]+ { return digits.join(""); }

s
	= [' '\t\r\n]