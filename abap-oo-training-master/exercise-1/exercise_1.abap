REPORT z_abap_oo_bank_1_jvc.

PARAMETERS p_amount TYPE maxbt.

INTERFACE lif_wage_type.
  METHODS get_amount RETURNING VALUE(rv_amount) TYPE maxbt.
  TYPES ty_t_wage_type TYPE STANDARD TABLE OF REF TO lif_wage_type WITH DEFAULT KEY.
ENDINTERFACE.

DATA gt_wage_types TYPE lif_wage_type=>ty_t_wage_type.

CLASS lcl_wage_type DEFINITION.
  PUBLIC SECTION.
    INTERFACES lif_wage_type.
    METHODS constructor IMPORTING iv_amount TYPE maxbt.
  PRIVATE SECTION.
    DATA mv_amount TYPE maxbt.
ENDCLASS.

CLASS lcl_wage_type IMPLEMENTATION.
  METHOD constructor.
    mv_amount = iv_amount.
  ENDMETHOD.

  METHOD lif_wage_type~get_amount.
    rv_amount = mv_amount.
  ENDMETHOD.
ENDCLASS.

CLASS lcl_wage_type_reader DEFINITION.
  PUBLIC SECTION.
    METHODS read RETURNING VALUE(rt_wage_types) TYPE lif_wage_type=>ty_t_wage_type.
ENDCLASS.

CLASS lcl_wage_type_reader IMPLEMENTATION.
  METHOD read.
    DATA lt_wage_types TYPE TABLE OF zjvc_wage_type.
    DATA lo_wage_type  TYPE REF TO lif_wage_type.

    SELECT * FROM zjvc_t_wage_type INTO TABLE lt_wage_types.

    LOOP AT lt_wage_types INTO DATA(ls_wage_type).
      CREATE OBJECT lo_wage_type TYPE lcl_wage_type
        EXPORTING iv_amount = ls_wage_type-amount.
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

    INSERT INTO zjvc_t_wage_type VALUES ls_wage_type.
  ENDMETHOD.
ENDCLASS.

END-OF-SELECTION.
  DATA lo_wage_type_code_generator TYPE REF TO zif_jvc_wt_code_generator.

  DATA lo_wage_type_reader TYPE REF TO lcl_wage_type_reader.
  DATA lo_wage_type_writer TYPE REF TO lcl_wage_type_writer.
  DATA lo_wage_type        TYPE REF TO lif_wage_type.

  CREATE OBJECT lo_wage_type_code_generator TYPE zcl_jvc_wt_code_generator.
  CREATE OBJECT lo_wage_type_reader.
  CREATE OBJECT lo_wage_type_writer
    EXPORTING io_wage_type_code_generator = lo_wage_type_code_generator.
  CREATE OBJECT lo_wage_type TYPE lcl_wage_type
    EXPORTING iv_amount = p_amount.

  lo_wage_type_writer->write( lo_wage_type ).
  LOOP AT lo_wage_type_reader->read( ) INTO lo_wage_type.
    WRITE:/ 'Amount: ', lo_wage_type->get_amount( ).
  ENDLOOP.