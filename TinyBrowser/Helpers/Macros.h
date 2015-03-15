#ifndef TANGO_MACROS_H
#define TANGO_MACROS_H

#define limit(a_, l_, r_) (((a_) < (l_)) ? (l_) : (((a_) > (r_)) ? (r_) : (a_)))

#define BlockWeakObject(o) __typeof__(o) __weak

#define BlockWeakSelf BlockWeakObject(self)

#endif