# Testing

## Objective

1. Test my implementation of a wage type writer
2. The tests should guarantee that:
   1. the correct type (deduction or earning) is being written
   2. that an exception is triggered when the amount is negative
   3. that message event is triggered only when the writing was sucessfull

## Details
   - We have a problem: our LCL_WAGE_TYPE_WRITER writes in a real database table, therefore we cannot test it
     - We have to mock the writing action
## Example

There is no diagram for this one. You can check the implementation on Z_ABAP_OO_BANK_JVC_TESTED in HRI. To practice, you can write tests for LCL_WAGE_TYPE_READER.

## Concepts (not necessarily OO Concepts)

- **Test Isolation**
  - Our class LCL_WAGE_TYPE_WRITER currently writes in the database. We have to isolate this behaviour so we can freely test. In the implementation, you can check that we created LIF_WT_TABLE_WRITER to isolate. The implementation of this class receives a table line and inserts it on the database.
- **Test Double**
  - Now that LCL_WAGE_TYPE_WRITER doesn't write the wage type in the database, but calls a LIF_WT_TABLE_WRITER, we can create a test double (LTD_WT_TABLE_WRITER) that mocks this behavior. This double class will allow us to test correctly.
  - **Question**: is the name LCL_WAGE_TYPE_WRITER still correct since it doesn't write anymore?
  - We also created a test double for the code generator class, to not actually reads productive places to get the next code.
  - Remember to use 'FOR TESTING' in your class definition.
- **Test Classes**
  - Contains the methods for testing and the auxiliar methods
- **Given/When/Then**
  - The test were written in the format given/when/then.
  - This approach is used to make test more easy to read. It also makes it easier to create new tests.
  - **Example**:
    - given_number( 10 )
    - when_multiplying_by_2( )
    - then_the_result_should_be( 20 )



