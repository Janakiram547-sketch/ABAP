REPORT z_abap_oo_bank_2_jvc.

PARAMETERS p_amount TYPE maxbt.
PARAMETERS p_deduc  TYPE xfeld AS CHECKBOX.

INTERFACE lif_wage_type.
    METHODS get_amount   RETURNING VALUE(rv_amount)       TYPE maxbt.
    METHODS is_deduction RETURNING VALUE(rv_is_deduction) TYPE abap_bool.

    TYPES ty_t_wage_type TYPE STANDARD TABLE OF REF TO lif_wage_type WITH DEFAULT KEY.
ENDINTERFACE.

CLASS lcl_wage_type DEFINITION .
  PUBLIC SECTION.
    INTERFACES lif_wage_type.
    METHODS constructor IMPORTING iv_amount TYPE maxbt.
  PRIVATE SECTION.
    DATA mv_amount TYPE maxbt.
    CONSTANTS gc_wage_type_ceilling TYPE maxbt VALUE '1000'.
ENDCLASS.

CLASS lcl_wage_type IMPLEMENTATION.
  METHOD constructor.
    mv_amount = iv_amount.
  ENDMETHOD.

  METHOD lif_wage_type~get_amount.
    IF mv_amount > gc_wage_type_ceilling.
      mv_amount = gc_wage_type_ceilling.
    ENDIF.
    rv_amount = mv_amount.
  ENDMETHOD.

  METHOD lif_wage_type~is_deduction.
    rv_is_deduction = abap_false.
  ENDMETHOD.
ENDCLASS.

CLASS lcl_deduction_wage_type DEFINITION INHERITING FROM lcl_wage_type.
  PUBLIC SECTION.
    METHODS constructor                IMPORTING iv_amount TYPE maxbt.
    METHODS lif_wage_type~is_deduction REDEFINITION.
ENDCLASS.

CLASS lcl_deduction_wage_type IMPLEMENTATION.
  METHOD constructor.
    super->constructor( iv_amount ).
  ENDMETHOD.

  METHOD lif_wage_type~is_deduction.
    rv_is_deduction = abap_true.
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
      CREATE OBJECT ro_wage_type TYPE lcl_wage_type
        EXPORTING iv_amount = iv_amount.
    ENDIF.
  ENDMETHOD.
ENDCLASS.

CLASS lcl_wage_type_reader DEFINITION.
  PUBLIC SECTION.
    METHODS constructor IMPORTING io_wage_type_factory TYPE REF TO lcl_wage_type_factory.
    METHODS read RETURNING VALUE(rt_wage_types) TYPE lif_wage_type=>ty_t_wage_type.
  PRIVATE SECTION.
    DATA mo_wage_type_factory TYPE REF TO lcl_wage_type_factory.
ENDCLASS.

CLASS lcl_wage_type_reader IMPLEMENTATION.
  METHOD constructor.
    mo_wage_type_factory = io_wage_type_factory.
  ENDMETHOD.

  METHOD read.
    DATA lt_wage_types TYPE TABLE OF zjvc_wage_type.
    DATA lo_wage_type  TYPE REF TO lif_wage_type.

    SELECT * FROM zjvc_t_wage_type INTO TABLE lt_wage_types.

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
    METHODS constructor IMPORTING io_wage_type_code_generator TYPE REF TO zif_jvc_wt_code_generator.
    METHODS write IMPORTING io_wage_type TYPE REF TO lif_wage_type.
  PRIVATE SECTION.
    DATA mo_wage_type_code_generator TYPE REF TO zif_jvc_wt_code_generator.
ENDCLASS.

CLASS lcl_wage_type_writer IMPLEMENTATION.
  METHOD constructor.
    mo_wage_type_code_generator = io_wage_type_code_generator.
  ENDMETHOD.

  METHOD write.
    DATA ls_wage_type TYPE zjvc_wage_type.

    ls_wage_type-mandt  = sy-mandt.
    ls_wage_type-code   = mo_wage_type_code_generator->generate( ).
    ls_wage_type-amount = io_wage_type->get_amount( ).
    ls_wage_type-type   = io_wage_type->is_deduction( ).

    INSERT INTO zjvc_t_wage_type VALUES ls_wage_type.
  ENDMETHOD.
ENDCLASS.

END-OF-SELECTION.
  DATA lo_wage_type_code_generator TYPE REF TO zif_jvc_wt_code_generator.

  DATA lo_wage_type_reader  TYPE REF TO lcl_wage_type_reader.
  DATA lo_wage_type_writer  TYPE REF TO lcl_wage_type_writer.
  DATA lo_wage_type         TYPE REF TO lif_wage_type.
  DATA lo_wage_type_factory TYPE REF TO lcl_wage_type_factory.

  CREATE OBJECT lo_wage_type_code_generator TYPE zcl_jvc_wt_code_generator.
  CREATE OBJECT lo_wage_type_writer EXPORTING io_wage_type_code_generator = lo_wage_type_code_generator.

  CREATE OBJECT lo_wage_type_factory.
  CREATE OBJECT lo_wage_type_reader EXPORTING io_wage_type_factory = lo_wage_type_factory.

  lo_wage_type = lo_wage_type_factory->make(
      iv_is_deduction = p_deduc
      iv_amount       = p_amount
  ).

  lo_wage_type_writer->write( lo_wage_type ).
  LOOP AT lo_wage_type_reader->read( ) INTO lo_wage_type.
    WRITE:/ 'Deduction : ', lo_wage_type->is_deduction( ), '| Amount: ', lo_wage_type->get_amount( ).
  ENDLOOP.