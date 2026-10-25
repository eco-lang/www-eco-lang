module {
  "func.func"() ({
        %5 = "eco.constant"() {kind = 2 : i32} : () -> !eco.value 
        %6 = "arith.constant"() {value = 4294967295 : i64} : () -> i64 
        %11 = "arith.constant"() {value = 0.25 : f64} : () -> f64 
        %7 = "eco.float.negate"(%11) {_operand_types = [f64]} : (f64) -> f64 
        %8 = "arith.constant"() {value = 32767 : i64} : () -> i64 
        %9 = "arith.constant"() {value = 255 : i64} : () -> i64 
        %15 = "eco.construct.record"(%8, %9, %6, %7) {_operand_types = [i64, i64, i64, f64], field_count = 4, slot_kinds = array<i8: 1, 1, 1, 2>} : (i64, i64, i64, f64) -> !eco.value 
        %16 = "eco.construct.list"(%15, %5) {_operand_types = [!eco.value, !eco.value], head_kind = 0, head_unboxed = false} : (!eco.value, !eco.value) -> !eco.value 
        %17 = "arith.constant"() {value = 7 : i64} : () -> i64 
        %18 = "arith.constant"() {value = 1.5 : f64} : () -> f64 
        %23 = "arith.constant"() {value = 3 : i64} : () -> i64 
        %19 = "eco.int.negate"(%23) {_operand_types = [i64]} : (i64) -> i64 
        %20 = "arith.constant"() {value = 9 : i64} : () -> i64 
        %26 = "eco.construct.record"(%19, %20, %17, %18) {_operand_types = [i64, i64, i64, f64], field_count = 4, slot_kinds = array<i8: 1, 1, 1, 2>} : (i64, i64, i64, f64) -> !eco.value 
        %27 = "eco.construct.list"(%26, %16) {_operand_types = [!eco.value, !eco.value], head_kind = 0, head_unboxed = false} : (!eco.value, !eco.value) -> !eco.value 
        %0 = "eco.call"(%27) <{_operand_types = [!eco.value], callee = @BytesEncodeRecordListFusionTest_encode_$_4}> : (!eco.value) -> !eco.value 
        %29 = "eco.papCreate"() {arity = 3, function = @BytesEncodeRecordListFusionTest_lambda_0, num_captured = 0} : () -> !eco.value 
        %34 = "eco.constant.null_cons"() {tag = 1} : () -> !eco.value 
        %36 = "eco.papCreate"() {arity = 3, function = @Elm_Kernel_Bytes_read_u32, num_captured = 0} : () -> !eco.value 
        %37 = "eco.constant.null_cons"() {tag = 0} : () -> !eco.value 
        %38 = "eco.value.eq"(%34, %37) {_operand_types = [!eco.value, !eco.value]} : (!eco.value, !eco.value) -> i1 
        %39 = "eco.box"(%38) {_operand_types = [i1]} : (i1) -> !eco.value 
        %40 = "eco.papExtend"(%36, %39) {_operand_types = [!eco.value, !eco.value], remaining_arity = 3, slot_kinds = array<i8: 0>} : (!eco.value, !eco.value) -> !eco.value 
        %30 = "eco.construct.custom"(%40) {_operand_types = [!eco.value], constructor = "Decoder", size = 1, slot_kinds = array<i8: 0>, tag = 0} : (!eco.value) -> !eco.value 
        %31 = "eco.call"() <{callee = @BytesEncodeRecordListFusionTest_recordDecoder_$_9}> : () -> !eco.value 
        %32 = "eco.call"() <{callee = @BytesEncodeRecordListFusionTest_recordDecoder_$_9}> : () -> !eco.value 
        %44 = "eco.project.custom"(%30) {_operand_types = [!eco.value], field_index = 0} : (!eco.value) -> !eco.value 
        %45 = "eco.project.custom"(%31) {_operand_types = [!eco.value], field_index = 0} : (!eco.value) -> !eco.value 
        %46 = "eco.project.custom"(%32) {_operand_types = [!eco.value], field_index = 0} : (!eco.value) -> !eco.value 
        %47 = "eco.papCreate"(%44, %45, %46, %29) {_fast_evaluator = @BytesEncodeRecordListFusionTest_lambda_27$cap, _operand_types = [!eco.value, !eco.value, !eco.value, !eco.value], arity = 6, function = @BytesEncodeRecordListFusionTest_lambda_27$clo, num_captured = 4, slot_kinds = array<i8: 0, 0, 0, 0>} : (!eco.value, !eco.value, !eco.value, !eco.value) -> !eco.value 
        %48 = "eco.construct.custom"(%47) {_operand_types = [!eco.value], constructor = "Decoder", size = 1, slot_kinds = array<i8: 0>, tag = 0} : (!eco.value) -> !eco.value 
        %49 = "eco.project.custom"(%48) {_operand_types = [!eco.value], field_index = 0} : (!eco.value) -> !eco.value 
        %1 = "eco.call"(%49, %0) <{_operand_types = [!eco.value, !eco.value], callee = @Elm_Kernel_Bytes_decode}> : (!eco.value, !eco.value) -> !eco.value 
        %51 = "eco.string_literal"() {value = "width"} : () -> !eco.value 
        %52 = "eco.call"(%0) <{_operand_types = [!eco.value], callee = @Elm_Kernel_Bytes_width, eco.cse_safe}> : (!eco.value) -> i64 
        %2 = "eco.box"(%52) {_operand_types = [i64]} : (i64) -> !eco.value 
        "eco.dbg"(%51, %2) {_operand_types = [!eco.value, !eco.value], arg_type_ids = array<i64: 4, 1>} : (!eco.value, !eco.value) -> () 
        %54 = "eco.string_literal"() {value = "decoded"} : () -> !eco.value 
        %55 = "eco.string_literal"() {value = "failed"} : () -> !eco.value 
        %58 = "eco.get_tag"(%1) {_operand_types = [!eco.value]} : (!eco.value) -> i32 
        %59 = "arith.constant"() {value = 0 : i32} : () -> i32 
        %60 = "arith.cmpi"(%58, %59) {_operand_types = [i32, i32], predicate = 0 : i64} : (i32, i32) -> i1 
        %3 = "eco.case"(%60) ({
              %61 = "eco.project.custom"(%1) {_operand_types = [!eco.value], field_index = 0} : (!eco.value) -> !eco.value 
              "eco.yield"(%61) {_operand_types = [!eco.value]} : (!eco.value) -> () 
        }, {
              "eco.yield"(%55) {_operand_types = [!eco.value]} : (!eco.value) -> () 
        }) {_operand_types = [i1], case_kind = "bool", tags = array<i64: 1, 0>} : (i1) -> !eco.value 
        "eco.dbg"(%54, %3) {_operand_types = [!eco.value, !eco.value], arg_type_ids = array<i64: 4, 4>} : (!eco.value, !eco.value) -> () 
        %4 = "eco.string_literal"() {value = "done"} : () -> !eco.value 
        %64 = "eco.call"(%4) <{_operand_types = [!eco.value], callee = @Elm_Kernel_VirtualDom_text, eco.cse_safe}> : (!eco.value) -> !eco.value 
        "eco.return"(%64) {_operand_types = [!eco.value]} : (!eco.value) -> () 
  }) {eco.shadow_roots, function_type = () -> (!eco.value), sym_name = "BytesEncodeRecordListFusionTest_main_$_0", sym_visibility = "private"} : () -> () 
  "func.func"() ({
      ^bb0(%n: i64):
        %1 = "eco.int.negate"(%n) {_operand_types = [i64]} : (i64) -> i64 
        "eco.return"(%1) {_operand_types = [i64]} : (i64) -> () 
  }) {eco.logical_param_types = ["i64"], eco.logical_result_types = ["i64"], function_type = (i64) -> (i64), sym_name = "Basics_negate_$_1", sym_visibility = "private"} : () -> () 
  "func.func"() ({
      ^bb0(%n: f64):
        %1 = "eco.float.negate"(%n) {_operand_types = [f64]} : (f64) -> f64 
        "eco.return"(%1) {_operand_types = [f64]} : (f64) -> () 
  }) {eco.logical_param_types = ["f64"], eco.logical_result_types = ["f64"], function_type = (f64) -> (f64), sym_name = "Basics_negate_$_3", sym_visibility = "private"} : () -> () 
  "func.func"() ({
      ^bb0(%records: !eco.value):
        %1 = "eco.constant.null_cons"() {tag = 1} : () -> !eco.value 
        %2 = "eco.call"(%records) <{_operand_types = [!eco.value], callee = @List_length_$_24}> : (!eco.value) -> i64 
        %3 = "eco.construct.custom"(%1, %2) {_operand_types = [!eco.value, i64], constructor = "U32", size = 2, slot_kinds = array<i8: 0, 1>, tag = 5} : (!eco.value, i64) -> !eco.value 
        %4 = "eco.papCreate"() {arity = 1, function = @BytesEncodeRecordListFusionTest_encodeRecord_$_26, num_captured = 0} : () -> !eco.value 
        %5 = "eco.call"(%4, %records) <{_operand_types = [!eco.value, !eco.value], callee = @List_map_$_27}> : (!eco.value, !eco.value) -> !eco.value 
        %6 = "eco.construct.list"(%3, %5) {_operand_types = [!eco.value, !eco.value], head_kind = 0, head_unboxed = false} : (!eco.value, !eco.value) -> !eco.value 
        %7 = "arith.constant"() {value = 4 : i32} : () -> i32 
        %8 = "eco.call"(%records) <{_operand_types = [!eco.value], callee = @List_length_$_24}> : (!eco.value) -> i64 
        %9 = "arith.trunci"(%8) {_operand_types = [i64]} : (i64) -> i32 
        %10 = "arith.constant"() {value = 15 : i32} : () -> i32 
        %11 = "arith.muli"(%9, %10) {_operand_types = [i32, i32]} : (i32, i32) -> i32 
        %12 = "arith.addi"(%7, %11) : (i32, i32) -> i32 
        %13 = "bf.alloc"(%12) {_operand_types = [i32]} : (i32) -> !eco.value 
        %14 = "bf.cursor.init"(%13) {_operand_types = [!eco.value]} : (!eco.value) -> !bf.cursor 
        %15 = "eco.call"(%records) <{_operand_types = [!eco.value], callee = @List_length_$_24}> : (!eco.value) -> i64 
        %16 = "bf.write.u32"(%14, %15) {_operand_types = [!bf.cursor, i64], endianness = 1 : i32} : (!bf.cursor, i64) -> !bf.cursor 
        %17, %18 = "scf.while"(%16, %records) ({
            ^bb0(%19: !bf.cursor, %20: !eco.value):
              %21 = "eco.get_tag"(%20) {_operand_types = [!eco.value]} : (!eco.value) -> i32 
              %22 = "arith.constant"() {value = 65533 : i32} : () -> i32 
              %23 = "arith.cmpi"(%21, %22) {_operand_types = [i32, i32], predicate = 0} : (i32, i32) -> i1 
              %24 = "arith.constant"() {value = 1 : i1} : () -> i1 
              %25 = "arith.xori"(%23, %24) {_operand_types = [i1, i1]} : (i1, i1) -> i1 
              "scf.condition"(%25, %19, %20) {_operand_types = [i1, !bf.cursor, !eco.value]} : (i1, !bf.cursor, !eco.value) -> () 
        }, {
            ^bb0(%26: !bf.cursor, %27: !eco.value):
              %28 = "eco.project.list_head"(%27) {_operand_types = [!eco.value]} : (!eco.value) -> !eco.value 
              %29 = "eco.project.list_tail"(%27) {_operand_types = [!eco.value]} : (!eco.value) -> !eco.value 
              %30 = "eco.project.record"(%28) {_operand_types = [!eco.value], field_index = 2} : (!eco.value) -> i64 
              %31 = "bf.write.u32"(%26, %30) {_operand_types = [!bf.cursor, i64], endianness = 1 : i32} : (!bf.cursor, i64) -> !bf.cursor 
              %32 = "eco.project.record"(%28) {_operand_types = [!eco.value], field_index = 3} : (!eco.value) -> f64 
              %33 = "bf.write.f64"(%31, %32) {_operand_types = [!bf.cursor, f64], endianness = 0 : i32} : (!bf.cursor, f64) -> !bf.cursor 
              %34 = "eco.project.record"(%28) {_operand_types = [!eco.value], field_index = 0} : (!eco.value) -> i64 
              %35 = "bf.write.u16"(%33, %34) {_operand_types = [!bf.cursor, i64], endianness = 1 : i32} : (!bf.cursor, i64) -> !bf.cursor 
              %36 = "eco.project.record"(%28) {_operand_types = [!eco.value], field_index = 1} : (!eco.value) -> i64 
              %37 = "bf.write.u8"(%35, %36) {_operand_types = [!bf.cursor, i64]} : (!bf.cursor, i64) -> !bf.cursor 
              "scf.yield"(%37, %29) {_operand_types = [!bf.cursor, !eco.value]} : (!bf.cursor, !eco.value) -> () 
        }) {_operand_types = [!bf.cursor, !eco.value]} : (!bf.cursor, !eco.value) -> (!bf.cursor, !eco.value) 
        "eco.return"(%13) {_operand_types = [!eco.value]} : (!eco.value) -> () 
  }) {eco.logical_param_types = ["cons:v:v"], eco.logical_result_types = ["value"], function_type = (!eco.value) -> (!eco.value), sym_name = "BytesEncodeRecordListFusionTest_encode_$_4", sym_visibility = "private"} : () -> () 
  "func.func"() ({
      ^bb0(%r: !eco.value):
        %1 = "eco.project.record"(%r) {_operand_types = [!eco.value], field_index = 2} : (!eco.value) -> i64 
        %2 = "eco.string.from_int"(%1) {_operand_types = [i64]} : (i64) -> !eco.value 
        %3 = "eco.string_literal"() {value = " "} : () -> !eco.value 
        %4 = "eco.project.record"(%r) {_operand_types = [!eco.value], field_index = 3} : (!eco.value) -> f64 
        %5 = "eco.string.from_float"(%4) {_operand_types = [f64]} : (f64) -> !eco.value 
        %6 = "eco.string_literal"() {value = " "} : () -> !eco.value 
        %7 = "eco.project.record"(%r) {_operand_types = [!eco.value], field_index = 0} : (!eco.value) -> i64 
        %8 = "eco.string.from_int"(%7) {_operand_types = [i64]} : (i64) -> !eco.value 
        %9 = "eco.string_literal"() {value = " "} : () -> !eco.value 
        %10 = "eco.project.record"(%r) {_operand_types = [!eco.value], field_index = 1} : (!eco.value) -> i64 
        %11 = "eco.string.from_int"(%10) {_operand_types = [i64]} : (i64) -> !eco.value 
        %12 = "eco.string.append"(%9, %11) {_operand_types = [!eco.value, !eco.value]} : (!eco.value, !eco.value) -> !eco.value 
        %13 = "eco.string.append"(%8, %12) {_operand_types = [!eco.value, !eco.value]} : (!eco.value, !eco.value) -> !eco.value 
        %14 = "eco.string.append"(%6, %13) {_operand_types = [!eco.value, !eco.value]} : (!eco.value, !eco.value) -> !eco.value 
        %15 = "eco.string.append"(%5, %14) {_operand_types = [!eco.value, !eco.value]} : (!eco.value, !eco.value) -> !eco.value 
        %16 = "eco.string.append"(%3, %15) {_operand_types = [!eco.value, !eco.value]} : (!eco.value, !eco.value) -> !eco.value 
        %17 = "eco.string.append"(%2, %16) {_operand_types = [!eco.value, !eco.value]} : (!eco.value, !eco.value) -> !eco.value 
        "eco.return"(%17) {_operand_types = [!eco.value]} : (!eco.value) -> () 
  }) {eco.logical_param_types = ["record:4:i:i:i:f"], eco.logical_result_types = ["value"], function_type = (!eco.value) -> (!eco.value), sym_name = "BytesEncodeRecordListFusionTest_show_$_5", sym_visibility = "private"} : () -> () 
  "func.func"() ({
        %18 = "eco.constant.null_cons"() {tag = 1} : () -> !eco.value 
        "eco.return"(%18) {_operand_types = [!eco.value]} : (!eco.value) -> () 
  }) {eco.logical_param_types = [], eco.logical_result_types = ["value"], function_type = () -> (!eco.value), sym_name = "Bytes_BE_$_7", sym_visibility = "private"} : () -> () 
  "eco.global"() {sym_name = "__eco_caf$BytesEncodeRecordListFusionTest_recordDecoder_$_9"} : () -> () 
  "func.func"() ({
        %4 = "eco.constant.null_cons"() {tag = 1} : () -> !eco.value 
        %6 = "eco.papCreate"() {arity = 3, function = @Elm_Kernel_Bytes_read_u32, num_captured = 0} : () -> !eco.value 
        %7 = "eco.constant.null_cons"() {tag = 0} : () -> !eco.value 
        %8 = "eco.value.eq"(%4, %7) {_operand_types = [!eco.value, !eco.value]} : (!eco.value, !eco.value) -> i1 
        %9 = "eco.box"(%8) {_operand_types = [i1]} : (i1) -> !eco.value 
        %10 = "eco.papExtend"(%6, %9) {_operand_types = [!eco.value, !eco.value], remaining_arity = 3, slot_kinds = array<i8: 0>} : (!eco.value, !eco.value) -> !eco.value 
        %0 = "eco.construct.custom"(%10) {_operand_types = [!eco.value], constructor = "Decoder", size = 1, slot_kinds = array<i8: 0>, tag = 0} : (!eco.value) -> !eco.value 
        %12 = "eco.constant.null_cons"() {tag = 0} : () -> !eco.value 
        %14 = "eco.papCreate"() {arity = 3, function = @Elm_Kernel_Bytes_read_f64, num_captured = 0} : () -> !eco.value 
        %15 = "eco.constant.null_cons"() {tag = 0} : () -> !eco.value 
        %16 = "eco.value.eq"(%12, %15) {_operand_types = [!eco.value, !eco.value]} : (!eco.value, !eco.value) -> i1 
        %17 = "eco.box"(%16) {_operand_types = [i1]} : (i1) -> !eco.value 
        %18 = "eco.papExtend"(%14, %17) {_operand_types = [!eco.value, !eco.value], remaining_arity = 3, slot_kinds = array<i8: 0>} : (!eco.value, !eco.value) -> !eco.value 
        %1 = "eco.construct.custom"(%18) {_operand_types = [!eco.value], constructor = "Decoder", size = 1, slot_kinds = array<i8: 0>, tag = 0} : (!eco.value) -> !eco.value 
        %20 = "eco.constant.null_cons"() {tag = 1} : () -> !eco.value 
        %22 = "eco.papCreate"() {arity = 3, function = @Elm_Kernel_Bytes_read_i16, num_captured = 0} : () -> !eco.value 
        %23 = "eco.constant.null_cons"() {tag = 0} : () -> !eco.value 
        %24 = "eco.value.eq"(%20, %23) {_operand_types = [!eco.value, !eco.value]} : (!eco.value, !eco.value) -> i1 
        %25 = "eco.box"(%24) {_operand_types = [i1]} : (i1) -> !eco.value 
        %26 = "eco.papExtend"(%22, %25) {_operand_types = [!eco.value, !eco.value], remaining_arity = 3, slot_kinds = array<i8: 0>} : (!eco.value, !eco.value) -> !eco.value 
        %2 = "eco.construct.custom"(%26) {_operand_types = [!eco.value], constructor = "Decoder", size = 1, slot_kinds = array<i8: 0>, tag = 0} : (!eco.value) -> !eco.value 
        %3 = "eco.call"() <{callee = @Bytes_Decode_unsignedInt8_$_19}> : () -> !eco.value 
        %29 = "eco.project.custom"(%0) {_operand_types = [!eco.value], field_index = 0} : (!eco.value) -> !eco.value 
        %30 = "eco.project.custom"(%1) {_operand_types = [!eco.value], field_index = 0} : (!eco.value) -> !eco.value 
        %31 = "eco.project.custom"(%2) {_operand_types = [!eco.value], field_index = 0} : (!eco.value) -> !eco.value 
        %32 = "eco.project.custom"(%3) {_operand_types = [!eco.value], field_index = 0} : (!eco.value) -> !eco.value 
        %33 = "eco.papCreate"(%29, %30, %31, %32) {_fast_evaluator = @BytesEncodeRecordListFusionTest_lambda_28$cap, _operand_types = [!eco.value, !eco.value, !eco.value, !eco.value], arity = 6, function = @BytesEncodeRecordListFusionTest_lambda_28$clo, num_captured = 4, slot_kinds = array<i8: 0, 0, 0, 0>} : (!eco.value, !eco.value, !eco.value, !eco.value) -> !eco.value 
        %34 = "eco.construct.custom"(%33) {_operand_types = [!eco.value], constructor = "Decoder", size = 1, slot_kinds = array<i8: 0>, tag = 0} : (!eco.value) -> !eco.value 
        "eco.return"(%34) {_operand_types = [!eco.value]} : (!eco.value) -> () 
  }) {eco.caf_memo, function_type = () -> (!eco.value), sym_name = "BytesEncodeRecordListFusionTest_recordDecoder_$_9", sym_visibility = "private"} : () -> () 
  "func.func"() ({
      ^bb0(%_v0: !eco.value, %bs: !eco.value):
        %2 = "eco.project.custom"(%_v0) {_operand_types = [!eco.value], field_index = 0} : (!eco.value) -> !eco.value 
        %3 = "eco.call"(%2, %bs) <{_operand_types = [!eco.value, !eco.value], callee = @Elm_Kernel_Bytes_decode}> : (!eco.value, !eco.value) -> !eco.value 
        "eco.return"(%3) {_operand_types = [!eco.value]} : (!eco.value) -> () 
  }) {eco.logical_param_types = ["custom:0:1:v", "value"], eco.logical_result_types = ["value"], function_type = (!eco.value, !eco.value) -> (!eco.value), sym_name = "Bytes_Decode_decode_$_11", sym_visibility = "private"} : () -> () 
  "func.func"() ({
      ^bb0(%arg0: !eco.value):
        %1 = "eco.construct.custom"(%arg0) {_operand_types = [!eco.value], constructor = "Decoder", size = 1, slot_kinds = array<i8: 0>, tag = 0} : (!eco.value) -> !eco.value 
        "eco.return"(%1) {_operand_types = [!eco.value]} : (!eco.value) -> () 
  }) {eco.logical_param_types = [], eco.logical_result_types = ["custom:0:1:v"], function_type = (!eco.value) -> (!eco.value), sym_name = "Bytes_Decode_Decoder_$_15", sym_visibility = "private"} : () -> () 
  "func.func"() ({
        %2 = "eco.constant.null_cons"() {tag = 0} : () -> !eco.value 
        "eco.return"(%2) {_operand_types = [!eco.value]} : (!eco.value) -> () 
  }) {eco.logical_param_types = [], eco.logical_result_types = ["value"], function_type = () -> (!eco.value), sym_name = "Bytes_LE_$_16", sym_visibility = "private"} : () -> () 
  "eco.global"() {sym_name = "__eco_caf$Bytes_Decode_unsignedInt8_$_19"} : () -> () 
  "func.func"() ({
        %0 = "eco.papCreate"() {arity = 2, function = @Elm_Kernel_Bytes_read_u8, num_captured = 0} : () -> !eco.value 
        %1 = "eco.construct.custom"(%0) {_operand_types = [!eco.value], constructor = "Decoder", size = 1, slot_kinds = array<i8: 0>, tag = 0} : (!eco.value) -> !eco.value 
        "eco.return"(%1) {_operand_types = [!eco.value]} : (!eco.value) -> () 
  }) {eco.caf_memo, function_type = () -> (!eco.value), sym_name = "Bytes_Decode_unsignedInt8_$_19", sym_visibility = "private"} : () -> () 
  "func.func"() ({
      ^bb0(%arg0: !eco.value):
        %1 = "eco.construct.custom"(%arg0) {_operand_types = [!eco.value], constructor = "Decoder", size = 1, slot_kinds = array<i8: 0>, tag = 0} : (!eco.value) -> !eco.value 
        "eco.return"(%1) {_operand_types = [!eco.value]} : (!eco.value) -> () 
  }) {eco.logical_param_types = [], eco.logical_result_types = ["custom:0:1:v"], function_type = (!eco.value) -> (!eco.value), sym_name = "Bytes_Decode_Decoder_$_21", sym_visibility = "private"} : () -> () 
  "func.func"() ({
      ^bb0(%arg0: !eco.value):
        %1 = "eco.construct.custom"(%arg0) {_operand_types = [!eco.value], constructor = "Decoder", size = 1, slot_kinds = array<i8: 0>, tag = 0} : (!eco.value) -> !eco.value 
        "eco.return"(%1) {_operand_types = [!eco.value]} : (!eco.value) -> () 
  }) {eco.logical_param_types = [], eco.logical_result_types = ["custom:0:1:v"], function_type = (!eco.value) -> (!eco.value), sym_name = "Bytes_Decode_Decoder_$_22", sym_visibility = "private"} : () -> () 
  "func.func"() ({
      ^bb0(%arg0: !eco.value):
        %1 = "eco.construct.custom"(%arg0) {_operand_types = [!eco.value], constructor = "Decoder", size = 1, slot_kinds = array<i8: 0>, tag = 0} : (!eco.value) -> !eco.value 
        "eco.return"(%1) {_operand_types = [!eco.value]} : (!eco.value) -> () 
  }) {eco.logical_param_types = [], eco.logical_result_types = ["custom:0:1:v"], function_type = (!eco.value) -> (!eco.value), sym_name = "Bytes_Decode_Decoder_$_23", sym_visibility = "private"} : () -> () 
  "func.func"() ({
      ^bb0(%xs: !eco.value):
        %1 = "eco.papCreate"() {_result_kind = 1 : i8, arity = 2, function = @_tail_mono_inline_62_159, num_captured = 0} : () -> !eco.value 
        %3 = "arith.constant"() {value = 0 : i64} : () -> i64 
        %4 = "eco.papExtend"(%1, %3, %xs) {_call_kind = "direct_known_segmentation", _operand_types = [!eco.value, i64, !eco.value], _result_kind = 1 : i8, remaining_arity = 2, slot_kinds = array<i8: 1, 0>} : (!eco.value, i64, !eco.value) -> i64 
        "eco.return"(%4) {_operand_types = [i64]} : (i64) -> () 
  }) {eco.logical_param_types = ["cons:v:v"], eco.logical_result_types = ["i64"], function_type = (!eco.value) -> (i64), sym_name = "List_length_$_24", sym_visibility = "private"} : () -> () 
  "func.func"() ({
      ^bb0(%arg0: !eco.value, %arg1: i64):
        %2 = "eco.construct.custom"(%arg0, %arg1) {_operand_types = [!eco.value, i64], constructor = "U32", size = 2, slot_kinds = array<i8: 0, 1>, tag = 5} : (!eco.value, i64) -> !eco.value 
        "eco.return"(%2) {_operand_types = [!eco.value]} : (!eco.value) -> () 
  }) {eco.logical_param_types = [], eco.logical_result_types = ["value"], function_type = (!eco.value, i64) -> (!eco.value), sym_name = "Bytes_Encode_U32_$_25", sym_visibility = "private"} : () -> () 
  "func.func"() ({
      ^bb0(%r: !eco.value):
        %2 = "eco.constant"() {kind = 2 : i32} : () -> !eco.value 
        %3 = "eco.project.record"(%r) {_operand_types = [!eco.value], field_index = 1} : (!eco.value) -> i64 
        %4 = "eco.construct.custom"(%3) {_operand_types = [i64], constructor = "U8", size = 1, slot_kinds = array<i8: 1>, tag = 3} : (i64) -> !eco.value 
        %5 = "eco.construct.list"(%4, %2) {_operand_types = [!eco.value, !eco.value], head_kind = 0, head_unboxed = false} : (!eco.value, !eco.value) -> !eco.value 
        %6 = "eco.constant.null_cons"() {tag = 1} : () -> !eco.value 
        %7 = "eco.project.record"(%r) {_operand_types = [!eco.value], field_index = 0} : (!eco.value) -> i64 
        %8 = "eco.construct.custom"(%6, %7) {_operand_types = [!eco.value, i64], constructor = "I16", size = 2, slot_kinds = array<i8: 0, 1>, tag = 1} : (!eco.value, i64) -> !eco.value 
        %9 = "eco.construct.list"(%8, %5) {_operand_types = [!eco.value, !eco.value], head_kind = 0, head_unboxed = false} : (!eco.value, !eco.value) -> !eco.value 
        %10 = "eco.constant.null_cons"() {tag = 0} : () -> !eco.value 
        %11 = "eco.project.record"(%r) {_operand_types = [!eco.value], field_index = 3} : (!eco.value) -> f64 
        %12 = "eco.construct.custom"(%10, %11) {_operand_types = [!eco.value, f64], constructor = "F64", size = 2, slot_kinds = array<i8: 0, 2>, tag = 7} : (!eco.value, f64) -> !eco.value 
        %13 = "eco.construct.list"(%12, %9) {_operand_types = [!eco.value, !eco.value], head_kind = 0, head_unboxed = false} : (!eco.value, !eco.value) -> !eco.value 
        %14 = "eco.constant.null_cons"() {tag = 1} : () -> !eco.value 
        %15 = "eco.project.record"(%r) {_operand_types = [!eco.value], field_index = 2} : (!eco.value) -> i64 
        %16 = "eco.construct.custom"(%14, %15) {_operand_types = [!eco.value, i64], constructor = "U32", size = 2, slot_kinds = array<i8: 0, 1>, tag = 5} : (!eco.value, i64) -> !eco.value 
        %1 = "eco.construct.list"(%16, %13) {_operand_types = [!eco.value, !eco.value], head_kind = 0, head_unboxed = false} : (!eco.value, !eco.value) -> !eco.value 
        %18 = "arith.constant"() {value = 0 : i64} : () -> i64 
        %19 = "eco.call"(%18, %1) <{_operand_types = [i64, !eco.value], callee = @Bytes_Encode_getWidths_$_29}> : (i64, !eco.value) -> i64 
        %20 = "eco.construct.custom"(%19, %1) {_operand_types = [i64, !eco.value], constructor = "Seq", size = 2, slot_kinds = array<i8: 1, 0>, tag = 8} : (i64, !eco.value) -> !eco.value 
        "eco.return"(%20) {_operand_types = [!eco.value]} : (!eco.value) -> () 
  }) {eco.logical_param_types = ["record:4:i:i:i:f"], eco.logical_result_types = ["value"], function_type = (!eco.value) -> (!eco.value), sym_name = "BytesEncodeRecordListFusionTest_encodeRecord_$_26", sym_visibility = "private"} : () -> () 
  "func.func"() ({
      ^bb0(%f: !eco.value, %xs: !eco.value):
        %2 = "eco.papCreate"() {arity = 2, function = @BytesEncodeRecordListFusionTest_lambda_16, num_captured = 0} : () -> !eco.value 
        %3 = "eco.constant"() {kind = 2 : i32} : () -> !eco.value 
        %7 = "arith.constant"() {value = 0 : i64} : () -> i64 
        %8 = "eco.call"(%2, %3, %7, %xs) <{_operand_types = [!eco.value, !eco.value, i64, !eco.value], callee = @List_foldrHelper_$_33}> : (!eco.value, !eco.value, i64, !eco.value) -> !eco.value 
        "eco.return"(%8) {_operand_types = [!eco.value]} : (!eco.value) -> () 
  }) {eco.logical_param_types = ["value", "cons:v:v"], eco.logical_result_types = ["cons:v:v"], function_type = (!eco.value, !eco.value) -> (!eco.value), sym_name = "List_map_$_27", sym_visibility = "private"} : () -> () 
  "func.func"() ({
      ^bb0(%width: i64, %builders: !eco.value):
        %2 = "arith.constant"() {value = false} : () -> i1 
        %3 = "arith.constant"() {value = 0 : i64} : () -> i64 
        %4, %5, %6, %7 = "scf.while"(%width, %builders, %2, %3) ({
            ^bb0(%8: i64, %9: !eco.value, %10: i1, %11: i64):
              %13 = "arith.constant"() {value = true} : () -> i1 
              %12 = "arith.xori"(%10, %13) {_operand_types = [i1, i1]} : (i1, i1) -> i1 
              "scf.condition"(%12, %8, %9, %10, %11) {_operand_types = [i1, i64, !eco.value, i1, i64]} : (i1, i64, !eco.value, i1, i64) -> () 
        }, {
            ^bb0(%14: i64, %15: !eco.value, %16: i1, %17: i64):
              %18 = "eco.get_tag"(%15) {_operand_types = [!eco.value]} : (!eco.value) -> i32 
              %19 = "arith.constant"() {value = 65533 : i32} : () -> i32 
              %20 = "arith.cmpi"(%18, %19) {_operand_types = [i32, i32], predicate = 0 : i64} : (i32, i32) -> i1 
              %28, %29, %30, %31 = "eco.case"(%20) ({
                    %21 = "arith.constant"() {value = true} : () -> i1 
                    "eco.yield"(%14, %15, %21, %14) {_operand_types = [i64, !eco.value, i1, i64]} : (i64, !eco.value, i1, i64) -> () 
              }, {
                    %22 = "eco.project.list_head"(%15) {_operand_types = [!eco.value]} : (!eco.value) -> !eco.value 
                    %23 = "eco.project.list_tail"(%15) {_operand_types = [!eco.value]} : (!eco.value) -> !eco.value 
                    %24 = "eco.call"(%22) <{_operand_types = [!eco.value], callee = @Bytes_Encode_getWidth_$_31}> : (!eco.value) -> i64 
                    %25 = "eco.int.add"(%14, %24) {_operand_types = [i64, i64]} : (i64, i64) -> i64 
                    %26 = "arith.constant"() {value = false} : () -> i1 
                    %27 = "arith.constant"() {value = 0 : i64} : () -> i64 
                    "eco.yield"(%25, %23, %26, %27) {_operand_types = [i64, !eco.value, i1, i64]} : (i64, !eco.value, i1, i64) -> () 
              }) {_operand_types = [i1], case_kind = "bool", tags = array<i64: 1, 0>} : (i1) -> (i64, !eco.value, i1, i64) 
              "scf.yield"(%28, %29, %30, %31) {_operand_types = [i64, !eco.value, i1, i64]} : (i64, !eco.value, i1, i64) -> () 
        }) {_operand_types = [i64, !eco.value, i1, i64]} : (i64, !eco.value, i1, i64) -> (i64, !eco.value, i1, i64) 
        "eco.return"(%7) {_operand_types = [i64]} : (i64) -> () 
  }) {eco.logical_param_types = ["i64", "cons:v:v"], eco.logical_result_types = ["i64"], function_type = (i64, !eco.value) -> (i64), sym_name = "Bytes_Encode_getWidths_$_29", sym_visibility = "private"} : () -> () 
  "func.func"() ({
      ^bb0(%arg0: i64, %arg1: !eco.value):
        %2 = "eco.construct.custom"(%arg0, %arg1) {_operand_types = [i64, !eco.value], constructor = "Seq", size = 2, slot_kinds = array<i8: 1, 0>, tag = 8} : (i64, !eco.value) -> !eco.value 
        "eco.return"(%2) {_operand_types = [!eco.value]} : (!eco.value) -> () 
  }) {eco.logical_param_types = [], eco.logical_result_types = ["value"], function_type = (i64, !eco.value) -> (!eco.value), sym_name = "Bytes_Encode_Seq_$_30", sym_visibility = "private"} : () -> () 
  "func.func"() ({
      ^bb0(%builder: !eco.value):
        %15 = "eco.case"(%builder) ({
              %1 = "arith.constant"() {value = 1 : i64} : () -> i64 
              "eco.yield"(%1) {_operand_types = [i64]} : (i64) -> () 
        }, {
              %2 = "arith.constant"() {value = 2 : i64} : () -> i64 
              "eco.yield"(%2) {_operand_types = [i64]} : (i64) -> () 
        }, {
              %3 = "arith.constant"() {value = 4 : i64} : () -> i64 
              "eco.yield"(%3) {_operand_types = [i64]} : (i64) -> () 
        }, {
              %4 = "arith.constant"() {value = 1 : i64} : () -> i64 
              "eco.yield"(%4) {_operand_types = [i64]} : (i64) -> () 
        }, {
              %5 = "arith.constant"() {value = 2 : i64} : () -> i64 
              "eco.yield"(%5) {_operand_types = [i64]} : (i64) -> () 
        }, {
              %6 = "arith.constant"() {value = 4 : i64} : () -> i64 
              "eco.yield"(%6) {_operand_types = [i64]} : (i64) -> () 
        }, {
              %7 = "arith.constant"() {value = 4 : i64} : () -> i64 
              "eco.yield"(%7) {_operand_types = [i64]} : (i64) -> () 
        }, {
              %8 = "arith.constant"() {value = 8 : i64} : () -> i64 
              "eco.yield"(%8) {_operand_types = [i64]} : (i64) -> () 
        }, {
              %10 = "eco.project.custom"(%builder) {_operand_types = [!eco.value], field_index = 0} : (!eco.value) -> i64 
              "eco.yield"(%10) {_operand_types = [i64]} : (i64) -> () 
        }, {
              %12 = "eco.project.custom"(%builder) {_operand_types = [!eco.value], field_index = 0} : (!eco.value) -> i64 
              "eco.yield"(%12) {_operand_types = [i64]} : (i64) -> () 
        }, {
              %13 = "eco.project.custom"(%builder) {_operand_types = [!eco.value], field_index = 0} : (!eco.value) -> !eco.value 
              %14 = "eco.call"(%13) <{_operand_types = [!eco.value], callee = @Elm_Kernel_Bytes_width, eco.cse_safe}> : (!eco.value) -> i64 
              "eco.yield"(%14) {_operand_types = [i64]} : (i64) -> () 
        }) {_operand_types = [!eco.value], case_kind = "ctor", tags = array<i64: 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10>} : (!eco.value) -> i64 
        "eco.return"(%15) {_operand_types = [i64]} : (i64) -> () 
  }) {eco.logical_param_types = ["value"], eco.logical_result_types = ["i64"], function_type = (!eco.value) -> (i64), sym_name = "Bytes_Encode_getWidth_$_31", sym_visibility = "private"} : () -> () 
  "func.func"() ({
      ^bb0(%fn: !eco.value, %acc: !eco.value, %ctr: i64, %ls: !eco.value):
        %4 = "eco.get_tag"(%ls) {_operand_types = [!eco.value]} : (!eco.value) -> i32 
        %5 = "arith.constant"() {value = 65533 : i32} : () -> i32 
        %6 = "arith.cmpi"(%4, %5) {_operand_types = [i32, i32], predicate = 0 : i64} : (i32, i32) -> i1 
        %46 = "eco.case"(%6) ({
              "eco.yield"(%acc) {_operand_types = [!eco.value]} : (!eco.value) -> () 
        }, {
              %7 = "eco.project.list_head"(%ls) {_operand_types = [!eco.value]} : (!eco.value) -> !eco.value 
              %8 = "eco.project.list_tail"(%ls) {_operand_types = [!eco.value]} : (!eco.value) -> !eco.value 
              %9 = "eco.get_tag"(%8) {_operand_types = [!eco.value]} : (!eco.value) -> i32 
              %10 = "arith.constant"() {value = 65533 : i32} : () -> i32 
              %11 = "arith.cmpi"(%9, %10) {_operand_types = [i32, i32], predicate = 0 : i64} : (i32, i32) -> i1 
              %45 = "eco.case"(%11) ({
                    %12 = "eco.papExtend"(%fn, %7, %acc) {_call_kind = "singleton_fast", _capture_abi = [], _fast_evaluator = @BytesEncodeRecordListFusionTest_lambda_16, _operand_types = [!eco.value, !eco.value, !eco.value], remaining_arity = 2, slot_kinds = array<i8: 0, 0>} : (!eco.value, !eco.value, !eco.value) -> !eco.value 
                    "eco.yield"(%12) {_operand_types = [!eco.value]} : (!eco.value) -> () 
              }, {
                    %13 = "eco.project.list_head"(%8) {_operand_types = [!eco.value]} : (!eco.value) -> !eco.value 
                    %14 = "eco.project.list_tail"(%8) {_operand_types = [!eco.value]} : (!eco.value) -> !eco.value 
                    %15 = "eco.get_tag"(%14) {_operand_types = [!eco.value]} : (!eco.value) -> i32 
                    %16 = "arith.constant"() {value = 65533 : i32} : () -> i32 
                    %17 = "arith.cmpi"(%15, %16) {_operand_types = [i32, i32], predicate = 0 : i64} : (i32, i32) -> i1 
                    %44 = "eco.case"(%17) ({
                          %18 = "eco.papExtend"(%fn, %13, %acc) {_call_kind = "singleton_fast", _capture_abi = [], _fast_evaluator = @BytesEncodeRecordListFusionTest_lambda_16, _operand_types = [!eco.value, !eco.value, !eco.value], remaining_arity = 2, slot_kinds = array<i8: 0, 0>} : (!eco.value, !eco.value, !eco.value) -> !eco.value 
                          %19 = "eco.papExtend"(%fn, %7, %18) {_call_kind = "singleton_fast", _capture_abi = [], _fast_evaluator = @BytesEncodeRecordListFusionTest_lambda_16, _operand_types = [!eco.value, !eco.value, !eco.value], remaining_arity = 2, slot_kinds = array<i8: 0, 0>} : (!eco.value, !eco.value, !eco.value) -> !eco.value 
                          "eco.yield"(%19) {_operand_types = [!eco.value]} : (!eco.value) -> () 
                    }, {
                          %20 = "eco.project.list_head"(%14) {_operand_types = [!eco.value]} : (!eco.value) -> !eco.value 
                          %21 = "eco.project.list_tail"(%14) {_operand_types = [!eco.value]} : (!eco.value) -> !eco.value 
                          %22 = "eco.get_tag"(%21) {_operand_types = [!eco.value]} : (!eco.value) -> i32 
                          %23 = "arith.constant"() {value = 65533 : i32} : () -> i32 
                          %24 = "arith.cmpi"(%22, %23) {_operand_types = [i32, i32], predicate = 0 : i64} : (i32, i32) -> i1 
                          %43 = "eco.case"(%24) ({
                                %25 = "eco.papExtend"(%fn, %20, %acc) {_call_kind = "singleton_fast", _capture_abi = [], _fast_evaluator = @BytesEncodeRecordListFusionTest_lambda_16, _operand_types = [!eco.value, !eco.value, !eco.value], remaining_arity = 2, slot_kinds = array<i8: 0, 0>} : (!eco.value, !eco.value, !eco.value) -> !eco.value 
                                %26 = "eco.papExtend"(%fn, %13, %25) {_call_kind = "singleton_fast", _capture_abi = [], _fast_evaluator = @BytesEncodeRecordListFusionTest_lambda_16, _operand_types = [!eco.value, !eco.value, !eco.value], remaining_arity = 2, slot_kinds = array<i8: 0, 0>} : (!eco.value, !eco.value, !eco.value) -> !eco.value 
                                %27 = "eco.papExtend"(%fn, %7, %26) {_call_kind = "singleton_fast", _capture_abi = [], _fast_evaluator = @BytesEncodeRecordListFusionTest_lambda_16, _operand_types = [!eco.value, !eco.value, !eco.value], remaining_arity = 2, slot_kinds = array<i8: 0, 0>} : (!eco.value, !eco.value, !eco.value) -> !eco.value 
                                "eco.yield"(%27) {_operand_types = [!eco.value]} : (!eco.value) -> () 
                          }, {
                                %28 = "eco.project.list_head"(%21) {_operand_types = [!eco.value]} : (!eco.value) -> !eco.value 
                                %29 = "eco.project.list_tail"(%21) {_operand_types = [!eco.value]} : (!eco.value) -> !eco.value 
                                %31 = "arith.constant"() {value = 500 : i64} : () -> i64 
                                %32 = "eco.int.gt"(%ctr, %31) {_operand_types = [i64, i64]} : (i64, i64) -> i1 
                                %30 = "eco.case"(%32) ({
                                      %33 = "eco.call"(%29) <{_operand_types = [!eco.value], callee = @List_reverse_$_34}> : (!eco.value) -> !eco.value 
                                      %34 = "eco.call"(%fn, %acc, %33) <{_operand_types = [!eco.value, !eco.value, !eco.value], callee = @List_foldl_$_35}> : (!eco.value, !eco.value, !eco.value) -> !eco.value 
                                      "eco.yield"(%34) {_operand_types = [!eco.value]} : (!eco.value) -> () 
                                }, {
                                      %35 = "arith.constant"() {value = 1 : i64} : () -> i64 
                                      %36 = "eco.int.add"(%ctr, %35) {_operand_types = [i64, i64]} : (i64, i64) -> i64 
                                      %37 = "eco.call"(%fn, %acc, %36, %29) <{_operand_types = [!eco.value, !eco.value, i64, !eco.value], callee = @List_foldrHelper_$_33}> : (!eco.value, !eco.value, i64, !eco.value) -> !eco.value 
                                      "eco.yield"(%37) {_operand_types = [!eco.value]} : (!eco.value) -> () 
                                }) {_operand_types = [i1], case_kind = "bool", tags = array<i64: 1, 0>} : (i1) -> !eco.value 
                                %39 = "eco.papExtend"(%fn, %28, %30) {_call_kind = "singleton_fast", _capture_abi = [], _fast_evaluator = @BytesEncodeRecordListFusionTest_lambda_16, _operand_types = [!eco.value, !eco.value, !eco.value], remaining_arity = 2, slot_kinds = array<i8: 0, 0>} : (!eco.value, !eco.value, !eco.value) -> !eco.value 
                                %40 = "eco.papExtend"(%fn, %20, %39) {_call_kind = "singleton_fast", _capture_abi = [], _fast_evaluator = @BytesEncodeRecordListFusionTest_lambda_16, _operand_types = [!eco.value, !eco.value, !eco.value], remaining_arity = 2, slot_kinds = array<i8: 0, 0>} : (!eco.value, !eco.value, !eco.value) -> !eco.value 
                                %41 = "eco.papExtend"(%fn, %13, %40) {_call_kind = "singleton_fast", _capture_abi = [], _fast_evaluator = @BytesEncodeRecordListFusionTest_lambda_16, _operand_types = [!eco.value, !eco.value, !eco.value], remaining_arity = 2, slot_kinds = array<i8: 0, 0>} : (!eco.value, !eco.value, !eco.value) -> !eco.value 
                                %42 = "eco.papExtend"(%fn, %7, %41) {_call_kind = "singleton_fast", _capture_abi = [], _fast_evaluator = @BytesEncodeRecordListFusionTest_lambda_16, _operand_types = [!eco.value, !eco.value, !eco.value], remaining_arity = 2, slot_kinds = array<i8: 0, 0>} : (!eco.value, !eco.value, !eco.value) -> !eco.value 
                                "eco.yield"(%42) {_operand_types = [!eco.value]} : (!eco.value) -> () 
                          }) {_operand_types = [i1], case_kind = "bool", tags = array<i64: 1, 0>} : (i1) -> !eco.value 
                          "eco.yield"(%43) {_operand_types = [!eco.value]} : (!eco.value) -> () 
                    }) {_operand_types = [i1], case_kind = "bool", tags = array<i64: 1, 0>} : (i1) -> !eco.value 
                    "eco.yield"(%44) {_operand_types = [!eco.value]} : (!eco.value) -> () 
              }) {_operand_types = [i1], case_kind = "bool", tags = array<i64: 1, 0>} : (i1) -> !eco.value 
              "eco.yield"(%45) {_operand_types = [!eco.value]} : (!eco.value) -> () 
        }) {_operand_types = [i1], case_kind = "bool", tags = array<i64: 1, 0>} : (i1) -> !eco.value 
        "eco.return"(%46) {_operand_types = [!eco.value]} : (!eco.value) -> () 
  }) {eco.logical_param_types = ["value", "cons:v:v", "i64", "cons:v:v"], eco.logical_result_types = ["cons:v:v"], function_type = (!eco.value, !eco.value, i64, !eco.value) -> (!eco.value), sym_name = "List_foldrHelper_$_33", sym_visibility = "private"} : () -> () 
  "func.func"() ({
      ^bb0(%list: !eco.value):
        %1 = "eco.call"(%list) <{_operand_types = [!eco.value], callee = @Elm_Kernel_List_reverse, eco.cse_safe}> : (!eco.value) -> !eco.value 
        "eco.return"(%1) {_operand_types = [!eco.value]} : (!eco.value) -> () 
  }) {eco.logical_param_types = ["cons:v:v"], eco.logical_result_types = ["cons:v:v"], function_type = (!eco.value) -> (!eco.value), sym_name = "List_reverse_$_34", sym_visibility = "private"} : () -> () 
  "func.func"() ({
      ^bb0(%func: !eco.value, %acc: !eco.value, %list: !eco.value):
        %3 = "arith.constant"() {value = false} : () -> i1 
        %4 = "eco.constant"() {kind = 2 : i32} : () -> !eco.value 
        %5, %6, %7, %8, %9 = "scf.while"(%func, %acc, %list, %3, %4) ({
            ^bb0(%10: !eco.value, %11: !eco.value, %12: !eco.value, %13: i1, %14: !eco.value):
              %16 = "arith.constant"() {value = true} : () -> i1 
              %15 = "arith.xori"(%13, %16) {_operand_types = [i1, i1]} : (i1, i1) -> i1 
              "scf.condition"(%15, %10, %11, %12, %13, %14) {_operand_types = [i1, !eco.value, !eco.value, !eco.value, i1, !eco.value]} : (i1, !eco.value, !eco.value, !eco.value, i1, !eco.value) -> () 
        }, {
            ^bb0(%17: !eco.value, %18: !eco.value, %19: !eco.value, %20: i1, %21: !eco.value):
              %22 = "eco.get_tag"(%19) {_operand_types = [!eco.value]} : (!eco.value) -> i32 
              %23 = "arith.constant"() {value = 65533 : i32} : () -> i32 
              %24 = "arith.cmpi"(%22, %23) {_operand_types = [i32, i32], predicate = 0 : i64} : (i32, i32) -> i1 
              %31, %32, %33, %34, %35 = "eco.case"(%24) ({
                    %25 = "arith.constant"() {value = true} : () -> i1 
                    "eco.yield"(%17, %18, %19, %25, %18) {_operand_types = [!eco.value, !eco.value, !eco.value, i1, !eco.value]} : (!eco.value, !eco.value, !eco.value, i1, !eco.value) -> () 
              }, {
                    %26 = "eco.project.list_head"(%19) {_operand_types = [!eco.value]} : (!eco.value) -> !eco.value 
                    %27 = "eco.project.list_tail"(%19) {_operand_types = [!eco.value]} : (!eco.value) -> !eco.value 
                    %28 = "eco.papExtend"(%17, %26, %18) {_call_kind = "singleton_fast", _capture_abi = [], _fast_evaluator = @BytesEncodeRecordListFusionTest_lambda_16, _operand_types = [!eco.value, !eco.value, !eco.value], remaining_arity = 2, slot_kinds = array<i8: 0, 0>} : (!eco.value, !eco.value, !eco.value) -> !eco.value 
                    %29 = "arith.constant"() {value = false} : () -> i1 
                    %30 = "eco.constant"() {kind = 2 : i32} : () -> !eco.value 
                    "eco.yield"(%17, %28, %27, %29, %30) {_operand_types = [!eco.value, !eco.value, !eco.value, i1, !eco.value]} : (!eco.value, !eco.value, !eco.value, i1, !eco.value) -> () 
              }) {_operand_types = [i1], case_kind = "bool", tags = array<i64: 1, 0>} : (i1) -> (!eco.value, !eco.value, !eco.value, i1, !eco.value) 
              "scf.yield"(%31, %32, %33, %34, %35) {_operand_types = [!eco.value, !eco.value, !eco.value, i1, !eco.value]} : (!eco.value, !eco.value, !eco.value, i1, !eco.value) -> () 
        }) {_operand_types = [!eco.value, !eco.value, !eco.value, i1, !eco.value]} : (!eco.value, !eco.value, !eco.value, i1, !eco.value) -> (!eco.value, !eco.value, !eco.value, i1, !eco.value) 
        "eco.return"(%9) {_operand_types = [!eco.value]} : (!eco.value) -> () 
  }) {eco.logical_param_types = ["value", "cons:v:v", "cons:v:v"], eco.logical_result_types = ["cons:v:v"], function_type = (!eco.value, !eco.value, !eco.value) -> (!eco.value), sym_name = "List_foldl_$_35", sym_visibility = "private"} : () -> () 
  "func.func"() ({
      ^bb0(%arg0: !eco.value, %arg1: !eco.value):
        %2 = "eco.construct.list"(%arg0, %arg1) {_operand_types = [!eco.value, !eco.value], head_kind = 0, head_unboxed = false} : (!eco.value, !eco.value) -> !eco.value 
        "eco.return"(%2) {_operand_types = [!eco.value]} : (!eco.value) -> () 
  }) {eco.logical_param_types = ["record:4:i:i:i:f", "cons:v:v"], eco.logical_result_types = ["cons:v:v"], function_type = (!eco.value, !eco.value) -> (!eco.value), sym_name = "List_cons_$_36", sym_visibility = "private"} : () -> () 
  "func.func"() ({
      ^bb0(%func: !eco.value, %acc: !eco.value, %list: !eco.value):
        %3 = "arith.constant"() {value = false} : () -> i1 
        %4 = "eco.constant"() {kind = 2 : i32} : () -> !eco.value 
        %5, %6, %7, %8, %9 = "scf.while"(%func, %acc, %list, %3, %4) ({
            ^bb0(%10: !eco.value, %11: !eco.value, %12: !eco.value, %13: i1, %14: !eco.value):
              %16 = "arith.constant"() {value = true} : () -> i1 
              %15 = "arith.xori"(%13, %16) {_operand_types = [i1, i1]} : (i1, i1) -> i1 
              "scf.condition"(%15, %10, %11, %12, %13, %14) {_operand_types = [i1, !eco.value, !eco.value, !eco.value, i1, !eco.value]} : (i1, !eco.value, !eco.value, !eco.value, i1, !eco.value) -> () 
        }, {
            ^bb0(%17: !eco.value, %18: !eco.value, %19: !eco.value, %20: i1, %21: !eco.value):
              %22 = "eco.get_tag"(%19) {_operand_types = [!eco.value]} : (!eco.value) -> i32 
              %23 = "arith.constant"() {value = 65533 : i32} : () -> i32 
              %24 = "arith.cmpi"(%22, %23) {_operand_types = [i32, i32], predicate = 0 : i64} : (i32, i32) -> i1 
              %31, %32, %33, %34, %35 = "eco.case"(%24) ({
                    %25 = "arith.constant"() {value = true} : () -> i1 
                    "eco.yield"(%17, %18, %19, %25, %18) {_operand_types = [!eco.value, !eco.value, !eco.value, i1, !eco.value]} : (!eco.value, !eco.value, !eco.value, i1, !eco.value) -> () 
              }, {
                    %26 = "eco.project.list_head"(%19) {_operand_types = [!eco.value]} : (!eco.value) -> !eco.value 
                    %27 = "eco.project.list_tail"(%19) {_operand_types = [!eco.value]} : (!eco.value) -> !eco.value 
                    %28 = "eco.construct.list"(%26, %18) {_operand_types = [!eco.value, !eco.value], head_kind = 0, head_unboxed = false} : (!eco.value, !eco.value) -> !eco.value 
                    %29 = "arith.constant"() {value = false} : () -> i1 
                    %30 = "eco.constant"() {kind = 2 : i32} : () -> !eco.value 
                    "eco.yield"(%17, %28, %27, %29, %30) {_operand_types = [!eco.value, !eco.value, !eco.value, i1, !eco.value]} : (!eco.value, !eco.value, !eco.value, i1, !eco.value) -> () 
              }) {_operand_types = [i1], case_kind = "bool", tags = array<i64: 1, 0>} : (i1) -> (!eco.value, !eco.value, !eco.value, i1, !eco.value) 
              "scf.yield"(%31, %32, %33, %34, %35) {_operand_types = [!eco.value, !eco.value, !eco.value, i1, !eco.value]} : (!eco.value, !eco.value, !eco.value, i1, !eco.value) -> () 
        }) {_operand_types = [!eco.value, !eco.value, !eco.value, i1, !eco.value]} : (!eco.value, !eco.value, !eco.value, i1, !eco.value) -> (!eco.value, !eco.value, !eco.value, i1, !eco.value) 
        "eco.return"(%9) {_operand_types = [!eco.value]} : (!eco.value) -> () 
  }) {eco.logical_param_types = ["value", "cons:v:v", "cons:v:v"], eco.logical_result_types = ["cons:v:v"], function_type = (!eco.value, !eco.value, !eco.value) -> (!eco.value), sym_name = "List_foldl_$_37", sym_visibility = "private"} : () -> () 
  "func.func"() ({
      ^bb0(%arg0: !eco.value, %arg1: f64):
        %2 = "eco.construct.custom"(%arg0, %arg1) {_operand_types = [!eco.value, f64], constructor = "F64", size = 2, slot_kinds = array<i8: 0, 2>, tag = 7} : (!eco.value, f64) -> !eco.value 
        "eco.return"(%2) {_operand_types = [!eco.value]} : (!eco.value) -> () 
  }) {eco.logical_param_types = [], eco.logical_result_types = ["value"], function_type = (!eco.value, f64) -> (!eco.value), sym_name = "Bytes_Encode_F64_$_38", sym_visibility = "private"} : () -> () 
  "func.func"() ({
      ^bb0(%arg0: !eco.value, %arg1: i64):
        %2 = "eco.construct.custom"(%arg0, %arg1) {_operand_types = [!eco.value, i64], constructor = "I16", size = 2, slot_kinds = array<i8: 0, 1>, tag = 1} : (!eco.value, i64) -> !eco.value 
        "eco.return"(%2) {_operand_types = [!eco.value]} : (!eco.value) -> () 
  }) {eco.logical_param_types = [], eco.logical_result_types = ["value"], function_type = (!eco.value, i64) -> (!eco.value), sym_name = "Bytes_Encode_I16_$_39", sym_visibility = "private"} : () -> () 
  "func.func"() ({
      ^bb0(%arg0: i64):
        %1 = "eco.construct.custom"(%arg0) {_operand_types = [i64], constructor = "U8", size = 1, slot_kinds = array<i8: 1>, tag = 3} : (i64) -> !eco.value 
        "eco.return"(%1) {_operand_types = [!eco.value]} : (!eco.value) -> () 
  }) {eco.logical_param_types = [], eco.logical_result_types = ["value"], function_type = (i64) -> (!eco.value), sym_name = "Bytes_Encode_U8_$_40", sym_visibility = "private"} : () -> () 
  "func.func"() ({
      ^bb0(%x: !eco.value, %acc: !eco.value):
        %5 = "eco.call"(%x) <{_operand_types = [!eco.value], callee = @BytesEncodeRecordListFusionTest_encodeRecord_$_26}> : (!eco.value) -> !eco.value 
        %6 = "eco.construct.list"(%5, %acc) {_operand_types = [!eco.value, !eco.value], head_kind = 0, head_unboxed = false} : (!eco.value, !eco.value) -> !eco.value 
        "eco.return"(%6) {_operand_types = [!eco.value]} : (!eco.value) -> () 
  }) {eco.logical_param_types = ["record:4:i:i:i:f", "cons:v:v"], eco.logical_result_types = ["cons:v:v"], function_type = (!eco.value, !eco.value) -> (!eco.value), sym_name = "BytesEncodeRecordListFusionTest_lambda_16", sym_visibility = "private"} : () -> () 
  "func.func"() ({
      ^bb0(%mono_inline_64: i64, %mono_inline_65: !eco.value):
        %7 = "eco.papCreate"() {_result_kind = 1 : i8, arity = 2, function = @_tail_mono_inline_62_159, num_captured = 0} : () -> !eco.value 
        %8 = "arith.constant"() {value = false} : () -> i1 
        %9 = "arith.constant"() {value = 0 : i64} : () -> i64 
        %10, %11, %12, %13 = "scf.while"(%mono_inline_64, %mono_inline_65, %8, %9) ({
            ^bb0(%14: i64, %15: !eco.value, %16: i1, %17: i64):
              %19 = "arith.constant"() {value = true} : () -> i1 
              %18 = "arith.xori"(%16, %19) {_operand_types = [i1, i1]} : (i1, i1) -> i1 
              "scf.condition"(%18, %14, %15, %16, %17) {_operand_types = [i1, i64, !eco.value, i1, i64]} : (i1, i64, !eco.value, i1, i64) -> () 
        }, {
            ^bb0(%20: i64, %21: !eco.value, %22: i1, %23: i64):
              %24 = "eco.get_tag"(%21) {_operand_types = [!eco.value]} : (!eco.value) -> i32 
              %25 = "arith.constant"() {value = 65533 : i32} : () -> i32 
              %26 = "arith.cmpi"(%24, %25) {_operand_types = [i32, i32], predicate = 0 : i64} : (i32, i32) -> i1 
              %35, %36, %37, %38 = "eco.case"(%26) ({
                    %27 = "arith.constant"() {value = true} : () -> i1 
                    "eco.yield"(%20, %21, %27, %20) {_operand_types = [i64, !eco.value, i1, i64]} : (i64, !eco.value, i1, i64) -> () 
              }, {
                    %28 = "eco.project.list_head"(%21) {_operand_types = [!eco.value]} : (!eco.value) -> !eco.value 
                    %29 = "eco.project.list_tail"(%21) {_operand_types = [!eco.value]} : (!eco.value) -> !eco.value 
                    %31 = "arith.constant"() {value = 1 : i64} : () -> i64 
                    %32 = "eco.int.add"(%20, %31) {_operand_types = [i64, i64]} : (i64, i64) -> i64 
                    %33 = "arith.constant"() {value = false} : () -> i1 
                    %34 = "arith.constant"() {value = 0 : i64} : () -> i64 
                    "eco.yield"(%32, %29, %33, %34) {_operand_types = [i64, !eco.value, i1, i64]} : (i64, !eco.value, i1, i64) -> () 
              }) {_operand_types = [i1], case_kind = "bool", tags = array<i64: 1, 0>} : (i1) -> (i64, !eco.value, i1, i64) 
              "scf.yield"(%35, %36, %37, %38) {_operand_types = [i64, !eco.value, i1, i64]} : (i64, !eco.value, i1, i64) -> () 
        }) {_operand_types = [i64, !eco.value, i1, i64]} : (i64, !eco.value, i1, i64) -> (i64, !eco.value, i1, i64) 
        "eco.return"(%13) {_operand_types = [i64]} : (i64) -> () 
  }) {eco.logical_param_types = ["i64", "cons:v:v"], eco.logical_result_types = ["i64"], function_type = (i64, !eco.value) -> (i64), sym_name = "_tail_mono_inline_62_159", sym_visibility = "private"} : () -> () 
  "func.func"() ({
      ^bb0(%mono_inline_50: !eco.value, %mono_inline_49: !eco.value, %mono_inline_48: !eco.value, %mono_inline_47: !eco.value, %bites: !eco.value, %offset: i64):
        %39 = "eco.papExtend"(%mono_inline_50, %bites, %offset) {_call_kind = "segmentation_unknown", _operand_types = [!eco.value, !eco.value, i64], slot_kinds = array<i8: 0, 1>} : (!eco.value, !eco.value, i64) -> !eco.value 
        %42 = "eco.project.tuple2"(%39) {_operand_types = [!eco.value], field = 0} : (!eco.value) -> i64 
        %44 = "eco.project.tuple2"(%39) {_operand_types = [!eco.value], field = 1} : (!eco.value) -> i64 
        %45 = "eco.papExtend"(%mono_inline_49, %bites, %42) {_call_kind = "segmentation_unknown", _operand_types = [!eco.value, !eco.value, i64], slot_kinds = array<i8: 0, 1>} : (!eco.value, !eco.value, i64) -> !eco.value 
        %48 = "eco.project.tuple2"(%45) {_operand_types = [!eco.value], field = 0} : (!eco.value) -> i64 
        %50 = "eco.project.tuple2"(%45) {_operand_types = [!eco.value], field = 1} : (!eco.value) -> f64 
        %51 = "eco.papExtend"(%mono_inline_48, %bites, %48) {_call_kind = "segmentation_unknown", _operand_types = [!eco.value, !eco.value, i64], slot_kinds = array<i8: 0, 1>} : (!eco.value, !eco.value, i64) -> !eco.value 
        %54 = "eco.project.tuple2"(%51) {_operand_types = [!eco.value], field = 0} : (!eco.value) -> i64 
        %56 = "eco.project.tuple2"(%51) {_operand_types = [!eco.value], field = 1} : (!eco.value) -> i64 
        %57 = "eco.papExtend"(%mono_inline_47, %bites, %54) {_call_kind = "segmentation_unknown", _operand_types = [!eco.value, !eco.value, i64], slot_kinds = array<i8: 0, 1>} : (!eco.value, !eco.value, i64) -> !eco.value 
        %60 = "eco.project.tuple2"(%57) {_operand_types = [!eco.value], field = 0} : (!eco.value) -> i64 
        %62 = "eco.project.tuple2"(%57) {_operand_types = [!eco.value], field = 1} : (!eco.value) -> i64 
        %67 = "eco.construct.record"(%56, %62, %44, %50) {_operand_types = [i64, i64, i64, f64], field_count = 4, slot_kinds = array<i8: 1, 1, 1, 2>} : (i64, i64, i64, f64) -> !eco.value 
        %68 = "eco.construct.tuple2"(%60, %67) {_operand_types = [i64, !eco.value], unboxed_bitmap = 1} : (i64, !eco.value) -> !eco.value 
        "eco.return"(%68) {_operand_types = [!eco.value]} : (!eco.value) -> () 
  }) {eco.logical_param_types = ["value", "value", "value", "value", "value", "i64"], eco.logical_result_types = ["tuple2:i:v"], function_type = (!eco.value, !eco.value, !eco.value, !eco.value, !eco.value, i64) -> (!eco.value), sym_name = "BytesEncodeRecordListFusionTest_lambda_28$cap", sym_visibility = "private"} : () -> () 
  "func.func"() ({
      ^bb0(%closure: !eco.value, %bites: !eco.value, %offset: i64):
        %3 = "eco.project.closure"(%closure) {index = 0, is_unboxed = false} : (!eco.value) -> !eco.value 
        %4 = "eco.project.closure"(%closure) {index = 1, is_unboxed = false} : (!eco.value) -> !eco.value 
        %5 = "eco.project.closure"(%closure) {index = 2, is_unboxed = false} : (!eco.value) -> !eco.value 
        %6 = "eco.project.closure"(%closure) {index = 3, is_unboxed = false} : (!eco.value) -> !eco.value 
        %7 = "eco.call"(%3, %4, %5, %6, %bites, %offset) <{_operand_types = [!eco.value, !eco.value, !eco.value, !eco.value, !eco.value, i64], callee = @BytesEncodeRecordListFusionTest_lambda_28$cap}> : (!eco.value, !eco.value, !eco.value, !eco.value, !eco.value, i64) -> !eco.value 
        "eco.return"(%7) {_operand_types = [!eco.value]} : (!eco.value) -> () 
  }) {eco.logical_param_types = ["value", "value", "i64"], eco.logical_result_types = ["tuple2:i:v"], function_type = (!eco.value, !eco.value, i64) -> (!eco.value), sym_name = "BytesEncodeRecordListFusionTest_lambda_28$clo", sym_visibility = "private"} : () -> () 
  "func.func"() ({
      ^bb0(%mono_inline_23: !eco.value, %mono_inline_22: !eco.value, %mono_inline_21: !eco.value, %mono_inline_8: !eco.value, %bites: !eco.value, %offset: i64):
        %33 = "eco.papExtend"(%mono_inline_23, %bites, %offset) {_call_kind = "segmentation_unknown", _operand_types = [!eco.value, !eco.value, i64], slot_kinds = array<i8: 0, 1>} : (!eco.value, !eco.value, i64) -> !eco.value 
        %36 = "eco.project.tuple2"(%33) {_operand_types = [!eco.value], field = 0} : (!eco.value) -> i64 
        %38 = "eco.project.tuple2"(%33) {_operand_types = [!eco.value], field = 1} : (!eco.value) -> i64 
        %39 = "eco.papExtend"(%mono_inline_22, %bites, %36) {_call_kind = "segmentation_unknown", _operand_types = [!eco.value, !eco.value, i64], slot_kinds = array<i8: 0, 1>} : (!eco.value, !eco.value, i64) -> !eco.value 
        %42 = "eco.project.tuple2"(%39) {_operand_types = [!eco.value], field = 0} : (!eco.value) -> i64 
        %44 = "eco.project.tuple2"(%39) {_operand_types = [!eco.value], field = 1} : (!eco.value) -> !eco.value 
        %45 = "eco.papExtend"(%mono_inline_21, %bites, %42) {_call_kind = "segmentation_unknown", _operand_types = [!eco.value, !eco.value, i64], slot_kinds = array<i8: 0, 1>} : (!eco.value, !eco.value, i64) -> !eco.value 
        %48 = "eco.project.tuple2"(%45) {_operand_types = [!eco.value], field = 0} : (!eco.value) -> i64 
        %50 = "eco.project.tuple2"(%45) {_operand_types = [!eco.value], field = 1} : (!eco.value) -> !eco.value 
        %51 = "eco.papExtend"(%mono_inline_8, %38, %44, %50) {_call_kind = "singleton_fast", _capture_abi = [], _fast_evaluator = @BytesEncodeRecordListFusionTest_lambda_0, _operand_types = [!eco.value, i64, !eco.value, !eco.value], remaining_arity = 3, slot_kinds = array<i8: 1, 0, 0>} : (!eco.value, i64, !eco.value, !eco.value) -> !eco.value 
        %52 = "eco.construct.tuple2"(%48, %51) {_operand_types = [i64, !eco.value], unboxed_bitmap = 1} : (i64, !eco.value) -> !eco.value 
        "eco.return"(%52) {_operand_types = [!eco.value]} : (!eco.value) -> () 
  }) {eco.logical_param_types = ["value", "value", "value", "value", "value", "i64"], eco.logical_result_types = ["tuple2:i:v"], function_type = (!eco.value, !eco.value, !eco.value, !eco.value, !eco.value, i64) -> (!eco.value), sym_name = "BytesEncodeRecordListFusionTest_lambda_27$cap", sym_visibility = "private"} : () -> () 
  "func.func"() ({
      ^bb0(%closure: !eco.value, %bites: !eco.value, %offset: i64):
        %3 = "eco.project.closure"(%closure) {index = 0, is_unboxed = false} : (!eco.value) -> !eco.value 
        %4 = "eco.project.closure"(%closure) {index = 1, is_unboxed = false} : (!eco.value) -> !eco.value 
        %5 = "eco.project.closure"(%closure) {index = 2, is_unboxed = false} : (!eco.value) -> !eco.value 
        %6 = "eco.project.closure"(%closure) {index = 3, is_unboxed = false} : (!eco.value) -> !eco.value 
        %7 = "eco.call"(%3, %4, %5, %6, %bites, %offset) <{_operand_types = [!eco.value, !eco.value, !eco.value, !eco.value, !eco.value, i64], callee = @BytesEncodeRecordListFusionTest_lambda_27$cap}> : (!eco.value, !eco.value, !eco.value, !eco.value, !eco.value, i64) -> !eco.value 
        "eco.return"(%7) {_operand_types = [!eco.value]} : (!eco.value) -> () 
  }) {eco.logical_param_types = ["value", "value", "i64"], eco.logical_result_types = ["tuple2:i:v"], function_type = (!eco.value, !eco.value, i64) -> (!eco.value), sym_name = "BytesEncodeRecordListFusionTest_lambda_27$clo", sym_visibility = "private"} : () -> () 
  "func.func"() ({
      ^bb0(%count: i64, %a: !eco.value, %b: !eco.value):
        %33 = "eco.string_literal"() {value = "count "} : () -> !eco.value 
        %34 = "eco.string.from_int"(%count) {_operand_types = [i64]} : (i64) -> !eco.value 
        %35 = "eco.string_literal"() {value = ": "} : () -> !eco.value 
        %36 = "eco.call"(%a) <{_operand_types = [!eco.value], callee = @BytesEncodeRecordListFusionTest_show_$_5}> : (!eco.value) -> !eco.value 
        %37 = "eco.string_literal"() {value = "; "} : () -> !eco.value 
        %38 = "eco.call"(%b) <{_operand_types = [!eco.value], callee = @BytesEncodeRecordListFusionTest_show_$_5}> : (!eco.value) -> !eco.value 
        %39 = "eco.string.append"(%37, %38) {_operand_types = [!eco.value, !eco.value]} : (!eco.value, !eco.value) -> !eco.value 
        %40 = "eco.string.append"(%36, %39) {_operand_types = [!eco.value, !eco.value]} : (!eco.value, !eco.value) -> !eco.value 
        %41 = "eco.string.append"(%35, %40) {_operand_types = [!eco.value, !eco.value]} : (!eco.value, !eco.value) -> !eco.value 
        %42 = "eco.string.append"(%34, %41) {_operand_types = [!eco.value, !eco.value]} : (!eco.value, !eco.value) -> !eco.value 
        %43 = "eco.string.append"(%33, %42) {_operand_types = [!eco.value, !eco.value]} : (!eco.value, !eco.value) -> !eco.value 
        "eco.return"(%43) {_operand_types = [!eco.value]} : (!eco.value) -> () 
  }) {eco.logical_param_types = ["i64", "record:4:i:i:i:f", "record:4:i:i:i:f"], eco.logical_result_types = ["value"], function_type = (i64, !eco.value, !eco.value) -> (!eco.value), sym_name = "BytesEncodeRecordListFusionTest_lambda_0", sym_visibility = "private"} : () -> () 
  "func.func"() ({
        %0 = "eco.call"() <{callee = @BytesEncodeRecordListFusionTest_main_$_0}> : () -> !eco.value 
        "eco.return"(%0) {_operand_types = [!eco.value]} : (!eco.value) -> () 
  }) {eco.list_chunks, function_type = () -> (!eco.value), sym_name = "main", sym_visibility = "private"} : () -> () 
  "func.func"() ({
      ^bb0(%arg0: !eco.value, %arg1: !eco.value):
        %2 = "eco.constant"() {kind = 2 : i32} : () -> !eco.value 
        "eco.return"(%2) {_operand_types = [!eco.value]} : (!eco.value) -> () 
  }) {eco.logical_param_types = ["value", "value"], eco.logical_result_types = ["value"], function_type = (!eco.value, !eco.value) -> (!eco.value), is_kernel = true, sym_name = "Elm_Kernel_Bytes_decode", sym_visibility = "private"} : () -> () 
  "func.func"() ({
      ^bb0(%arg0: !eco.value, %arg1: !eco.value, %arg2: i64):
        %3 = "eco.constant"() {kind = 2 : i32} : () -> !eco.value 
        "eco.return"(%3) {_operand_types = [!eco.value]} : (!eco.value) -> () 
  }) {eco.logical_param_types = ["value", "value", "i64"], eco.logical_result_types = ["value"], function_type = (!eco.value, !eco.value, i64) -> (!eco.value), is_kernel = true, sym_name = "Elm_Kernel_Bytes_read_f64", sym_visibility = "private"} : () -> () 
  "func.func"() ({
      ^bb0(%arg0: !eco.value, %arg1: !eco.value, %arg2: i64):
        %3 = "eco.constant"() {kind = 2 : i32} : () -> !eco.value 
        "eco.return"(%3) {_operand_types = [!eco.value]} : (!eco.value) -> () 
  }) {eco.logical_param_types = ["value", "value", "i64"], eco.logical_result_types = ["value"], function_type = (!eco.value, !eco.value, i64) -> (!eco.value), is_kernel = true, sym_name = "Elm_Kernel_Bytes_read_i16", sym_visibility = "private"} : () -> () 
  "func.func"() ({
      ^bb0(%arg0: !eco.value, %arg1: !eco.value, %arg2: i64):
        %3 = "eco.constant"() {kind = 2 : i32} : () -> !eco.value 
        "eco.return"(%3) {_operand_types = [!eco.value]} : (!eco.value) -> () 
  }) {eco.logical_param_types = ["value", "value", "i64"], eco.logical_result_types = ["value"], function_type = (!eco.value, !eco.value, i64) -> (!eco.value), is_kernel = true, sym_name = "Elm_Kernel_Bytes_read_u32", sym_visibility = "private"} : () -> () 
  "func.func"() ({
      ^bb0(%arg0: !eco.value, %arg1: i64):
        %2 = "eco.constant"() {kind = 2 : i32} : () -> !eco.value 
        "eco.return"(%2) {_operand_types = [!eco.value]} : (!eco.value) -> () 
  }) {eco.logical_param_types = ["value", "i64"], eco.logical_result_types = ["value"], function_type = (!eco.value, i64) -> (!eco.value), is_kernel = true, sym_name = "Elm_Kernel_Bytes_read_u8", sym_visibility = "private"} : () -> () 
  "func.func"() ({
      ^bb0(%arg0: !eco.value):
        %1 = "arith.constant"() {value = 0 : i64} : () -> i64 
        "eco.return"(%1) {_operand_types = [i64]} : (i64) -> () 
  }) {eco.gc_leaf, eco.logical_param_types = ["value"], eco.logical_result_types = ["i64"], function_type = (!eco.value) -> (i64), is_kernel = true, sym_name = "Elm_Kernel_Bytes_width", sym_visibility = "private"} : () -> () 
  "func.func"() ({
      ^bb0(%arg0: !eco.value):
        %1 = "eco.constant"() {kind = 2 : i32} : () -> !eco.value 
        "eco.return"(%1) {_operand_types = [!eco.value]} : (!eco.value) -> () 
  }) {eco.logical_param_types = ["value"], eco.logical_result_types = ["value"], function_type = (!eco.value) -> (!eco.value), is_kernel = true, sym_name = "Elm_Kernel_List_reverse", sym_visibility = "private"} : () -> () 
  "func.func"() ({
      ^bb0(%arg0: !eco.value):
        %1 = "eco.constant"() {kind = 2 : i32} : () -> !eco.value 
        "eco.return"(%1) {_operand_types = [!eco.value]} : (!eco.value) -> () 
  }) {eco.logical_param_types = ["value"], eco.logical_result_types = ["value"], function_type = (!eco.value) -> (!eco.value), is_kernel = true, sym_name = "Elm_Kernel_VirtualDom_text", sym_visibility = "private"} : () -> () 
  "eco.type_table"() {ctors = [[0, 4, 4, 0], [1, 5, 4, 0], [0, 6, 6, 0], [0, 7, 6, 1], [0, 7, 9, 1], [0, 7, 12, 1], [0, 7, 15, 1], [0, 9, 16, 1], [1, 10, 17, 2], [2, 12, 19, 2], [3, 13, 21, 1], [4, 14, 22, 2], [5, 15, 24, 2], [6, 16, 26, 2], [7, 17, 28, 2], [8, 18, 30, 2], [9, 19, 32, 2], [10, 6, 34, 1]], fields = [[0, 1], [1, 1], [2, 1], [3, 0], [0, 1], [0, 4], [8, 9], [0, 1], [0, 2], [8, 13], [0, 1], [0, 1], [8, 17], [0, 1], [0, 0], [8, 21], [8, 1], [8, 5], [11, 1], [8, 5], [11, 1], [8, 1], [8, 5], [11, 1], [8, 5], [11, 1], [8, 5], [11, 0], [8, 5], [11, 0], [8, 1], [11, 23], [8, 1], [11, 4], [8, 8]], func_args = [1, 8, 1, 8, 1, 8, 1, 8], strings = ["delta", "flag", "id", "value", "LE", "BE", "Bytes", "Decoder", "field0", "I8", "I16", "field1", "I32", "U8", "U16", "U32", "F32", "F64", "Seq", "Utf8"], types = [[0, 0, 1], [1, 0, 0], [2, 3, 0, 4], [3, 1, 2], [4, 0, 4], [5, 4, 0, 2], [6, 2, 2, 4, 2], [7, 5, 0, 1, 6], [8, 4, 2, 1], [9, 5, 1, 1, 7], [10, 4, 3, 1], [11, 2, 2, 7, 2], [12, 5, 2, 1, 11], [13, 5, 3, 1, 12], [14, 4, 4, 1], [15, 2, 2, 10, 2], [16, 5, 4, 1, 15], [17, 5, 5, 1, 16], [18, 4, 5, 1], [19, 2, 2, 13, 2], [20, 5, 6, 1, 19], [21, 5, 7, 1, 20], [22, 4, 6, 1], [23, 1, 24], [24, 4, 7, 11]]} : () -> () 
} 
