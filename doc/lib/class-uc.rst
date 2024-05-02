Class (UC lib)
==============
:Description: Foundation for class-like behavior and data instances of
  composite types.
:Created: 2020-09-16
:Updated: 2024-01-18

Beyond simple types, there are complex types that combine several datums in a
single, logical type. Structures and classes are two forms of complex types.
Although more fundamental, the current approach steps over ``struct``\ 's and
provides a naive approach to write `classes` and define `class inheritance`.

Class-like behavior for Bash uses global arrays and random, numerical Ids to
store attribute values new 'objects', and ``class_<Class-name>_``
handler functions to define `methods` (or other calls) to be performed on
such objects.

See uc-class for util. This lib itself may move to us-class or similar in
+U-S later.

Abstract
--------
Class-like behaviour is simulated by generating routines that trigger lookups
for method calls in per-type call handler routines. These routines have several
variables made available including `$self` and `$super` to perform sub-calls,
as well as special status codes for return to trigger different call handler
lookup behavior.

Definitions currently required for new types are a. one bases list, and b. one
call handler function. It is expected that there will be a great many different
types, the implementation does not even restrict to single type inheritance or
even static inheritance. Giving almost component like possibilities (interface
querying, adapters, etc.). So instead of relying on lib-uc.lib a more compact,
terse way to provide new types is preferable. Also because a lot of
initialization is added to scripts this way, it is important to initialize
strictly only what is needed and not necessarily everything that has been
loaded.

Therefor the class 'load' hook is introduced instead of lib 'load' hook to
initialize the global variables that the type relies upon. This is also a
convenient place to indicate lib dependencies and the base types as well.
The filename pattern ``<typeid>.class.sh`` is introduced to hold one single
type (and even any number of hidden or private types).

Note that while the class 'load' hook is invoked by a parameterized lib-load,
its env parameters will need to be adjusted back again to load regular libs
from that same class 'load' hook.

Background
----------
In programming languages the concept of class refers to a certain specific
abstractions of data types, the details of which each arrives at their own
implementation.

Regular data types are meant to understand bits and bytes at a certain memory
location, whereas class data types are only sets of functions and variable
types that can be used to operate on data provided in a dynamic context called
`object oriented programming`. Ofcourse definitions on the topic vary. However
in principle this is based on single or multiple inheritance concepts and also
overloading, for functions as well as variables tied to the 'object' type, and
perhaps other more specialized concepts.

Each class extends an existing set of classes (methods and properties). And
depending on the class' requirements, any number of different instances can
be created for a class. Having instances allows a programmer to write
routines into any number of different types for extending and modifying the
class resolution order. This can potentially alleviate having to write many
essentially similar routines but for many different contexts.

Shell script classes
____________________
Shells by their very nature hardly had any data type. There is just strings of
maybe characters, and integers smaller than intmax_t.

Modern shells can do some limited array-type variable handling. There
is no nesting. And of course shell command evaluation does not get any faster.
But it is there. And it is a cleaner way to store large amounts of indexed
data than using dynamic variable names.

To emulate OOP style classes, a quirky feature of (Bash) shell command
evaluation is exploited where a trailing space is hidden in a variable that
as a value expresses a command prefix, which in turn leads to execute a
certain call for a specific object instance. All of the actual data is kept
in global arrays, while the variable reference itself holds the Id, but also
the concrete type to aid the generated class routine and helpers to run the
call chain.

These following script lines illustrate and explain current usage more
plainly::

  # Create a new instance at variable ctx
  create ctx MyClass
  # has now set: ctx="class.MyClass MyClass <Instance-id> "

  # Invokes '.call' looking at every type until E:done is returned
  $ctx.call arg1 arg2

Implementation
--------------
class-{init,load} are the handlers to use to ease progressive loading of
types and all their dependent types. These rely on lib-require and so no
lib should use any of these routines from their lib 'load' or 'init' hooks.

After the class 'load' hook for a type, the Class:static_type[<Type>] and
other declarations should be done. E.g. the optional Class:libs[<Type>]
and Class:rel-types[<Type> should be defined. The calls implemented by the
type must be in function class_<Type>_.

The function class-load-all can be used to do all of above based on the list
of names in the ctx-class-types variable. That variable is also used with
class-define-all by default.

class-define-all builds a complete
resolution sequence for each type and store that at Class:type[<Type>],
and dynamically defines a function routine called class.<Type>.

XXX: cleanup above, but want some testing in place first

TODO:
class-declare see uc-class.lib

class loop context: TODO: adapt properly for static calls

global variables:
  SELF_NAME: value of ConcreteType ie. class-word symbol for concrete type
  OBJ_ID: same as id
  CLASS_{IDX,TYPERES,TYPEC}:
  call: full name for current call
  id: instance id of current class context
  self: call-reference of class.<ConcreteType> <ConcreteType> <Id>

per-invocation variables:

  CLASS_NAME: name of currently called class
  SUPER_NAME: name of super class of currently called
  super: call-reference of class.<SuperName> <SelfName>

Functions
_________
class-attributes
  Helper for class-attributes that lists all variables for current class
  context.

class-calls
  Helper for class-loop that lists all accepted calls for current class
  context. See also class-methods and class-attributes.

class-compile-mro <Class-name>
  Helper to cache entire MRO (see class-static-mro) at Class:type[<Class-name>]
  XXX: prefixed by the Class-name again

class-define <Class-name>
  Generate class.<Class-name> wrapper function to work with instance aka
  object contexts.

class-define-all <Class-names...>
  Given existing types, compile and store the method resolution order (MRO)
  (aka inheritance chain) and define a wrapper function.

class-defined <Class-name>
  Helper that checks if function class.<Class-name> has been defined.

class-del <Var-name>
  Destroy instance by calling destructor and then unsetting variable.

class-exists <Class-name>
  Helper that checks if Class:static-type[<Class-name>] has been defined.

class-info
  Helper for class-loop that prints the class name and object Id of current
  class context.

class-init <Class-names...>
  Prepare everything for given classes to create new instances using
  class-new. This includes:
    - class-load
    - class-define-all, for given classes and all base types

class-load [<Class-names...>]
  Load classes (source scripts and run load hooks) and prerequisite libs.

  Loads given Class names or all ctx-class-types. Loading includes:
    - class-load-def
    - running class 'load' hook
    - class-load-libs
    - recursing for all classes on inheritance chain

  This can be invoked multiple times and it will not reperform any of above
  functions for the same class twice.

  XXX: this loads more specific classes first (and load hook, and libs),
  before more generic base classes. May want an option to go depth first as
  it were, however load hook is required to know about base classes in the
  first place.

class-load-def <Class-name>
  Try to find sh lib or class.sh file and source that (uses lib-uc.lib).

class-load-libs <Class-names...>
  Accumulate all Class:libs[<Class>] values and run lib-require with those
  as arguments, if any.

class-loaded <Class-name>
  Helper that checks if function class_<Class-name>_ has been defined. When
  relying on class-load, this implies the class 'load' hook has been invoked.

class-loop
  This is main function used for all class-like call handler behavior.

  TODO: description

class-methods
  Helper for class-loop that lists all calls for current context that start
  with a period '.' character and matching a more restricted character range.
  See also class-calls and class-attributes.

class-query
  Return zero status when Class matches Class:instance[id], and else update
  setting and return E:done status.
  XXX: this does not run constructors; the caller will need to ensure the
  'type' has been properly adapted.

class-resolve
  TODO: rewrite or remove? class-loop only needs sequence, no pairs

class-run-call <Args...>
  Small helper for class-loop that relays invocation to class_<Type>_ for
  current context.

class-static-mro <Class-name>
  Retrieve entire MRO sequence from Class:static-type[<Class-name>].

class-switch <Var-name> [<Class-name>]
  Changes type (calling class-query) and updates variable reference and
  returns zero. This can also be used to update variable reference if
  Class:instance[id] has been changed.

class-typeset
  Helper for class-loop that dumps each class_<Type>_ declaration on
  inheritance chain.

Classes
-------
class.Class
  .class-attributes
    List type-attribute pairs of current type, retrieved from compgen.

  .class-refs
    Create by-name declarations, for given attributes or all attributes of
    class.

  --fields
    Fields are tracked per static class, but defined per concrete class so
    while each NRO should probably use a unique set of names, it is not
    impossible to have identical names on different classes ending up in the
    same MRO.

    Finding these names is trivial using compgen prefix expansion, so they are
    currently not tracked otherwise. See class-attributes.

    Array lookups are generally faster than any other sort of invocation,
    however when left undefined (unset) then detecting their existance incurs
    some overhead.


..
