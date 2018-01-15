module boiler.testsuite;

import std.string;
import core.exception;

alias Test = void delegate();
class TestSuite {
	private Test[] tests;

	void Setup() {}
	void Teardown() {}

	void Run() {
		foreach (test; tests) {
			try {
				Setup();
				test();
			}
			finally {
				Teardown();
			}
		}
	}

	void AddTest(Test test) {
		tests ~= test;
	}
}

template assertOp(string op)
{
    void assertOp(T1, T2)(T1 lhs, T2 rhs,
                          string file = __FILE__,
                          size_t line = __LINE__)
    {
        string msg = format("(%s %s %s) failed.", lhs, op, rhs);

        mixin(format(q{
            if (!(lhs %s rhs)) throw new AssertError(msg, file, line);
        }, op));
    }
}

alias assertOp!"==" assertEqual;
alias assertOp!"!=" assertNotEqual;
alias assertOp!">" assertGreaterThan;
alias assertOp!">=" assertGreaterThanOrEqual;
