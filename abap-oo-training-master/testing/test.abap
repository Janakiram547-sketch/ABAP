REPORT z_abap_oo_bank_2_jvc.

PARAMETERS p_amount TYPE maxbt.
PARAMETERS p_deduc  TYPE xfeld AS CHECKBOX.

CLASS lcx_wage_with_invalid_amount DEFINITION INHERITING FROM cx_static_check.
ENDCLASS.
CLASS lcx_wage_with_invalid_amount IMPLEMENTATION.
ENDCLASS.

INTERFACE lif_wage_type_events.
  EVENTS sucessfull_write EXPORTING VALUE(iv_code) TYPE numc10.
ENDINTERFACE.

INTERFACE lif_wage_type_events_handler.
  METHODS on_sucessfull_write FOR EVENT sucessfull_write OF lif_wage_type_events IMPORTING iv_code.
  METHODS get_messages        RETURNING VALUE(rt_messages) TYPE string_table.
ENDINTERFACE.

CLASS lcl_wage_type_events_handler DEFINITION.
  PUBLIC SECTION.
    METHODS constructor.
    INTERFACES lif_wage_type_events_handler.
  PRIVATE SECTION.
    DATA mt_messages TYPE string_table.
ENDCLASS.

CLASS lcl_wage_type_events_handler IMPLEMENTATION.
  METHOD constructor.
    SET HANDLER me->lif_wage_type_events_handler~on_sucessfull_write FOR ALL INSTANCES.
  ENDMETHOD.

  METHOD lif_wage_type_events_handler~on_sucessfull_write.
    APPEND |Wage type written with code { iv_code }| TO mt_messages.
  ENDMETHOD.

  METHOD lif_wage_type_events_handler~get_messages.
    rt_messages = mt_messages.
  ENDMETHOD.
ENDCLASS.

CLASS lcl_wage_type DEFINITION ABSTRACT.
  PUBLIC SECTION.
    TYPES ty_t_wage_type TYPE STANDARD TABLE OF REF TO lcl_wage_type WITH DEFAULT KEY.

    METHODS constructor  IMPORTING iv_amount TYPE maxbt.
    METHODS get_amount   RETURNING VALUE(rv_amount) TYPE maxbt.
    METHODS is_deduction ABSTRACT RETURNING VALUE(rv_is_deduction) TYPE abap_bool.
  PRIVATE SECTION.
    DATA mv_amount TYPE maxbt.
    CONSTANTS gc_wage_type_ceilling TYPE maxbt VALUE '1000'.
ENDCLASS.

INTERFACE lif_wage_type_reader.
    METHODS read RETURNING VALUE(rt_wage_types) TYPE lcl_wage_type=>ty_t_wage_type.
ENDINTERFACE.

INTERFACE lif_wage_type_writer.
    METHODS write IMPORTING io_wage_type TYPE REF TO lcl_wage_type
      RAISING lcx_wage_with_invalid_amount.
ENDINTERFACE.

INTERFACE lif_wt_table_writer.
  METHODS write IMPORTING is_wage_type TYPE zjvc_wage_type.
ENDINTERFACE.

CLASS lcl_wt_table_writer DEFINITION.
  PUBLIC SECTION.
    INTERFACES lif_wt_table_writer.
ENDCLASS.
CLASS lcl_wt_table_writer IMPLEMENTATION.
  METHOD lif_wt_table_writer~write.
    INSERT INTO zjvc_t_wage_type VALUES is_wage_type.
  ENDMETHOD.
ENDCLASS.

INTERFACE lif_wt_table_reader.
  TYPES ty_t_table_wage_type TYPE STANDARD TABLE OF zjvc_wage_type WITH DEFAULT KEY.
  METHODS read RETURNING VALUE(rt_wage_types) TYPE ty_t_table_wage_type.
ENDINTERFACE.

CLASS lcl_wt_table_reader DEFINITION.
  PUBLIC SECTION.
    INTERFACES lif_wt_table_reader.
ENDCLASS.
CLASS lcl_wt_table_reader IMPLEMENTATION.
  METHOD lif_wt_table_reader~read.
    SELECT * FROM zjvc_t_wage_type INTO TABLE rt_wage_types.
  ENDMETHOD.
ENDCLASS.

CLASS lcl_wage_type IMPLEMENTATION.
  METHOD constructor.
    mv_amount = iv_amount.
  ENDMETHOD.

  METHOD get_amount.
    IF mv_amount > gc_wage_type_ceilling.
      mv_amount = gc_wage_type_ceilling.
    ENDIF.
    rv_amount = mv_amount.
  ENDMETHOD.
ENDCLASS.

CLASS lcl_deduction_wage_type DEFINITION INHERITING FROM lcl_wage_type.
  PUBLIC SECTION.
    METHODS constructor  IMPORTING iv_amount TYPE maxbt.
    METHODS is_deduction REDEFINITION.
ENDCLASS.

CLASS lcl_deduction_wage_type IMPLEMENTATION.
  METHOD constructor.
    super->constructor( iv_amount ).
  ENDMETHOD.

  METHOD is_deduction.
    rv_is_deduction = abap_true.
  ENDMETHOD.
ENDCLASS.

CLASS lcl_earning_wage_type DEFINITION INHERITING FROM lcl_wage_type.
  PUBLIC SECTION.
    METHODS constructor  IMPORTING iv_amount TYPE maxbt.
    METHODS is_deduction REDEFINITION.
ENDCLASS.

CLASS lcl_earning_wage_type IMPLEMENTATION.
  METHOD constructor.
    super->constructor( iv_amount ).
  ENDMETHOD.

  METHOD is_deduction.
    rv_is_deduction = abap_false.
  ENDMETHOD.
ENDCLASS.

CLASS lcl_wage_type_factory DEFINITION.
  PUBLIC SECTION.
    METHODS make IMPORTING iv_is_deduction TYPE abap_bool
                           iv_amount       TYPE maxbt
                 RETURNING VALUE(ro_wage_type) TYPE REF TO lcl_wage_type.
ENDCLASS.

CLASS lcl_wage_type_factory IMPLEMENTATION.

  METHOD make.
    IF iv_is_deduction = abap_true.
      CREATE OBJECT ro_wage_type TYPE lcl_deduction_wage_type
        EXPORTING iv_amount = iv_amount.
    ELSE.
      CREATE OBJECT ro_wage_type TYPE lcl_earning_wage_type
        EXPORTING iv_amount = iv_amount.
    ENDIF.
  ENDMETHOD.
ENDCLASS.

CLASS lcl_wage_type_reader DEFINITION.
  PUBLIC SECTION.
    METHODS constructor IMPORTING io_wage_type_factory TYPE REF TO lcl_wage_type_factory
                                  io_wt_table_reader   TYPE REF TO lif_wt_table_reader.
    INTERFACES lif_wage_type_reader.
  PRIVATE SECTION.
    DATA mo_wage_type_factory TYPE REF TO lcl_wage_type_factory.
    DATA mo_wt_table_reader   TYPE REF TO lif_wt_table_reader.
ENDCLASS.

CLASS lcl_wage_type_reader IMPLEMENTATION.
  METHOD constructor.
    mo_wage_type_factory = io_wage_type_factory.
    mo_wt_table_reader   = io_wt_table_reader.
  ENDMETHOD.

  METHOD lif_wage_type_reader~read.
    DATA lo_wage_type  TYPE REF TO lcl_wage_type.
    DATA(lt_wage_types) = mo_wt_table_reader->read( ).

    LOOP AT lt_wage_types INTO DATA(ls_wage_type).
      lo_wage_type = mo_wage_type_factory->make(
          iv_is_deduction = ls_wage_type-type
          iv_amount       = ls_wage_type-amount
      ).
      APPEND lo_wage_type TO rt_wage_types.
    ENDLOOP.
  ENDMETHOD.
ENDCLASS.

CLASS lcl_wage_type_writer DEFINITION.
  PUBLIC SECTION.
    INTERFACES lif_wage_type_writer.
    INTERFACES lif_wage_type_events.
    METHODS constructor IMPORTING io_wage_type_code_generator TYPE REF TO zif_jvc_wt_code_generator
                                  io_wt_table_writer          TYPE REF TO lif_wt_table_writer.
  PRIVATE SECTION.
    DATA mo_wage_type_code_generator TYPE REF TO zif_jvc_wt_code_generator.
    DATA mo_wt_table_writer          TYPE REF TO lif_wt_table_writer.
ENDCLASS.

CLASS lcl_wage_type_writer IMPLEMENTATION.
  METHOD constructor.
    mo_wage_type_code_generator = io_wage_type_code_generator.
    mo_wt_table_writer          = io_wt_table_writer.
  ENDMETHOD.

  METHOD lif_wage_type_writer~write.
    DATA ls_wage_type TYPE zjvc_wage_type.

    IF io_wage_type->get_amount( ) < 0.
      RAISE EXCEPTION TYPE lcx_wage_with_invalid_amount.
    ENDIF.

    ls_wage_type-mandt  = sy-mandt.
    ls_wage_type-code   = mo_wage_type_code_generator->generate( ).
    ls_wage_type-amount = io_wage_type->get_amount( ).
    ls_wage_type-type   = io_wage_type->is_deduction( ).

    mo_wt_table_writer->write( ls_wage_type ).

    RAISE EVENT lif_wage_type_events~sucessfull_write
      EXPORTING iv_code = ls_wage_type-code.
  ENDMETHOD.
ENDCLASS.

END-OF-SELECTION.
  DATA lo_wage_type_code_generator TYPE REF TO zif_jvc_wt_code_generator.

  DATA lo_wage_type_reader         TYPE REF TO lif_wage_type_reader.
  DATA lo_wage_type_writer         TYPE REF TO lif_wage_type_writer.
  DATA lo_wage_type                TYPE REF TO lcl_wage_type.
  DATA lo_wage_type_factory        TYPE REF TO lcl_wage_type_factory.
  DATA lo_wage_type_events_handler TYPE REF TO lif_wage_type_events_handler.

  CREATE OBJECT lo_wage_type_code_generator TYPE zcl_jvc_wt_code_generator.
  CREATE OBJECT lo_wage_type_writer  TYPE lcl_wage_type_writer
    EXPORTING io_wage_type_code_generator = lo_wage_type_code_generator
              io_wt_table_writer          = NEW lcl_wt_table_writer( ).

  CREATE OBJECT lo_wage_type_factory.
  CREATE OBJECT lo_wage_type_reader TYPE lcl_wage_type_reader
    EXPORTING io_wage_type_factory = lo_wage_type_factory
              io_wt_table_reader   = NEW lcl_wt_table_reader( ).

  CREATE OBJECT lo_wage_type_events_handler TYPE lcl_wage_type_events_handler.

  lo_wage_type = lo_wage_type_factory->make(
      iv_is_deduction = p_deduc
      iv_amount       = p_amount
  ).

  TRY.
    lo_wage_type_writer->write( lo_wage_type ).
  CATCH lcx_wage_with_invalid_amount.
    WRITE:/ 'Wage type amount cannot be negative'.
    EXIT.
  ENDTRY.

  LOOP AT lo_wage_type_events_handler->get_messages( ) INTO DATA(lv_message).
    WRITE:/ lv_message.
  ENDLOOP.

  LOOP AT lo_wage_type_reader->read( ) INTO lo_wage_type.
    WRITE:/ 'Deduction : ', lo_wage_type->is_deduction( ), '| Amount: ', lo_wage_type->get_amount( ).
  ENDLOOP.


  CLASS ltd_wage_type_code_generator DEFINITION FOR TESTING.
    PUBLIC SECTION.
      INTERFACES zif_jvc_wt_code_generator.
  ENDCLASS.
  CLASS ltd_wage_type_code_generator IMPLEMENTATION.
    METHOD zif_jvc_wt_code_generator~generate.
      rv_code = '1'.
    ENDMETHOD.
  ENDCLASS.

  CLASS ltd_wt_table_writer DEFINITION FOR TESTING.
    PUBLIC SECTION.
      INTERFACES lif_wt_table_writer.
      DATA ms_wage_type TYPE zjvc_wage_type.
  ENDCLASS.
  CLASS ltd_wt_table_writer IMPLEMENTATION.
    METHOD lif_wt_table_writer~write.
      ms_wage_type = is_wage_type.
    ENDMETHOD.
  ENDCLASS.

  CLASS ltc_wage_type_writer DEFINITION FOR TESTING DURATION SHORT RISK LEVEL HARMLESS.
    PRIVATE SECTION.
      METHODS setup.

      METHODS given_wage_type_object IMPORTING io_wage_type TYPE REF TO lcl_wage_type.
      METHODS when_writing.
      METHODS then_written_wt_should_be IMPORTING is_wage_type TYPE zjvc_wage_type.
      METHODS then_exception_should_happen.
      METHODS then_exception_shouldnt_happen.
      METHODS then_messages_should_be IMPORTING it_messages TYPE string_table.

      METHODS invalid_amount      FOR TESTING.
      METHODS deduction_wage_type FOR TESTING.
      METHODS earning_wage_type   FOR TESTING.

      DATA mo_wage_type_code_generator TYPE REF TO ltd_wage_type_code_generator.
      DATA mo_wt_table_writer          TYPE REF TO ltd_wt_table_writer.
      DATA mo_wage_type                TYPE REF TO lcl_wage_type.
      DATA mo_wage_types_event_handler TYPE REF TO lif_wage_type_events_handler.

      DATA mo_wage_type_writer         TYPE REF TO lif_wage_type_writer.
      DATA mv_exception_happened       TYPE abap_bool.
  ENDCLASS.

  CLASS ltc_wage_type_writer IMPLEMENTATION.

    METHOD setup.
     mo_wage_type_code_generator = NEW #( ).
     mo_wt_table_writer          = NEW #( ).
     mo_wage_type_writer = NEW lcl_wage_type_writer(
         io_wage_type_code_generator = mo_wage_type_code_generator
         io_wt_table_writer          = mo_wt_table_writer
     ).
     mo_wage_types_event_handler = NEW lcl_wage_type_events_handler( ).
    ENDMETHOD.

    METHOD invalid_amount.
      given_wage_type_object( NEW lcl_earning_wage_type( '-100.00' ) ).
      when_writing( ).
      then_written_wt_should_be( VALUE #( ) ).
      then_exception_should_happen( ).
      then_messages_should_be( VALUE #( ) ).
    ENDMETHOD.

    METHOD deduction_wage_type.
      given_wage_type_object( NEW lcl_deduction_wage_type( '100.00' ) ).
      when_writing( ).
      then_written_wt_should_be( VALUE #( mandt = sy-mandt code = '1' type = 'X' amount = '100.00' ) ).
      then_exception_shouldnt_happen( ).
      then_messages_should_be( VALUE #( ( |Wage type written with code 0000000001| ) ) ).
    ENDMETHOD.

    METHOD earning_wage_type.
      given_wage_type_object( NEW lcl_earning_wage_type( '100.00' ) ).
      when_writing( ).
      then_written_wt_should_be( VALUE #( mandt = sy-mandt code = '1' type = '' amount = '100.00' ) ).
      then_exception_shouldnt_happen( ).
      then_messages_should_be( VALUE #( ( |Wage type written with code 0000000001| ) ) ).
    ENDMETHOD.

    METHOD given_wage_type_object.
      mo_wage_type = io_wage_type.
    ENDMETHOD.

    METHOD when_writing.
      TRY.
        mo_wage_type_writer->write( mo_wage_type ).
      CATCH lcx_wage_with_invalid_amount.
        mv_exception_happened = abap_true.
      ENDTRY.
    ENDMETHOD.

    METHOD then_written_wt_should_be.
      cl_abap_unit_assert=>assert_equals(
          act = mo_wt_table_writer->ms_wage_type
          exp = is_wage_type
      ).
    ENDMETHOD.

    METHOD then_exception_should_happen.
      cl_abap_unit_assert=>assert_true( mv_exception_happened ).
    ENDMETHOD.

    METHOD then_exception_shouldnt_happen.
      cl_abap_unit_assert=>assert_false( mv_exception_happened ).
    ENDMETHOD.

    METHOD then_messages_should_be.
      cl_abap_unit_assert=>assert_equals(
          act = mo_wage_types_event_handler->get_messages( )
          exp = it_messages
      ).
    ENDMETHOD.

  ENDCLASS.