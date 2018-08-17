#include <stdio.h>
#include <stdarg.h>
#include <stdint.h>
#include <stdlib.h>
#include <stdbool.h>
#include <string.h>
#include <setjmp.h>
#include <stdnoreturn.h>
#include <math.h>

/*
 * Used functions:
 *
 * malloc
 * free
 * 
 */

struct qlstring {
	char* data;
	uint32_t length;
};

union qldata {
	double number;
	struct qlstring string;
};

struct qlvalue {
	uint16_t type;
	union qldata data;
};

inline struct qlvalue qlnumber(double data) {
	struct qlvalue result;
	result.type = 0;
	result.data.number = data;
	return result;
}

inline struct qlvalue qlstring(const char* data, uint32_t length) {
	struct qlvalue result;
	result.type = 1;
	result.data.string.data = (char*)data;
	result.data.string.length = length;
	return result;
}

void error() {

}

struct qlvalue qladd(struct qlvalue a, struct qlvalue b) {
	if (a.type != b.type) error();

	struct qlvalue result;
	if (a.type == 0) {
		result.type = 0;
		result.data.number = a.data.number + b.data.number;
	} else if (a.type == 1) {
		result.type = 1;
		// TODO result.data.string.data = 
	}

	return result;
}

struct qlvalue qlmul(struct qlvalue a, struct qlvalue b) {
	if (a.type != b.type) error();

	struct qlvalue result;
	if (a.type == 0) {
		result.type = 0;
		result.data.number = a.data.number * b.data.number;
	} else if (a.type == 1) {
		result.type = 1;
		// TODO result.data.string.data = 
	}

	return result;
}

struct qlvalue qlnil;

// TODO: temporary, remove
struct qlvalue l_variable_print(struct qlvalue thing) {
	if (thing.type == 0) {
		printf("%.14g\n", thing.data.number);
	}

	return qlnil;
}

struct l_class_Program {
	struct qlvalue l_variable_Main;
};

struct qlvalue l_method_Program_Main() {
	struct qlvalue l_variable_a = qlnumber((double)3);
	l_variable_print(l_variable_a);
	l_variable_a = qlnumber((double)4);
	return qladd(qlnumber((double)2), qlmul(l_variable_a, qlnumber((double)5)));
}

int main() {
	qlnil.type = 65535;
	double result = l_method_Program_Main().data.number;
	int status = (int)result;
	if ((double)status != result) {
		error();
	}
	return status;
}