module {
  "func.func"() ({
        %2 = "arith.constant"() {value = 300 : i64} : () -> i64 
        %3 = "arith.constant"() {value = 7 : i64} : () -> i64 
        %4 = "eco.construct.record"(%2, %3) {_operand_types = [i64, i64], field_count = 2, slot_kinds = array<i8: 1, 1>} : (i64, i64) -> !eco.value 
        %5 = "eco.call"(%4) <{_operand_types = [!eco.value], callee = @Bin_encodePoint_$_1}> : (!eco.value) -> !eco.value 
        %0 = "eco.call"(%5) <{_operand_types = [!eco.value], callee = @Elm_Kernel_Bytes_encode}> : (!eco.value) -> !eco.value 
        %7 = "eco.call"() <{callee = @Bin_decodePoint_$_2}> : () -> !eco.value 
        %8 = "eco.project.custom"(%7) {_operand_types = [!eco.value], field_index = 0} : (!eco.value) -> !eco.value 
        %1 = "eco.call"(%8, %0) <{_operand_types = [!eco.value, !eco.value], callee = @Elm_Kernel_Bytes_decode}> : (!eco.value, !eco.value) -> !eco.value 
        %10 = "eco.get_tag"(%1) {_operand_types = [!eco.value]} : (!eco.value) -> i32 
        %11 = "arith.constant"() {value = 0 : i32} : () -> i32 
        %12 = "arith.cmpi"(%10, %11) {_operand_types = [i32, i32], predicate = 0 : i64} : (i32, i32) -> i1 
        %23 = "eco.case"(%12) ({
              %13 = "eco.project.custom"(%1) {_operand_types = [!eco.value], field_index = 0} : (!eco.value) -> !eco.value 
              %15 = "eco.project.record"(%13) {_operand_types = [!eco.value], field_index = 0} : (!eco.value) -> i64 
              %16 = "eco.project.record"(%13) {_operand_types = [!eco.value], field_index = 1} : (!eco.value) -> i64 
              %17 = "eco.int.add"(%15, %16) {_operand_types = [i64, i64]} : (i64, i64) -> i64 
              %14 = "eco.string.from_int"(%17) {_operand_types = [i64]} : (i64) -> !eco.value 
              %19 = "eco.call"(%14) <{_operand_types = [!eco.value], callee = @Elm_Kernel_VirtualDom_text, eco.cse_safe}> : (!eco.value) -> !eco.value 
              "eco.yield"(%19) {_operand_types = [!eco.value]} : (!eco.value) -> () 
        }, {
              %20 = "eco.string_literal"() {value = "fail"} : () -> !eco.value 
              %22 = "eco.call"(%20) <{_operand_types = [!eco.value], callee = @Elm_Kernel_VirtualDom_text, eco.cse_safe}> : (!eco.value) -> !eco.value 
              "eco.yield"(%22) {_operand_types = [!eco.value]} : (!eco.value) -> () 
        }) {_operand_types = [i1], case_kind = "bool", tags = array<i64: 1, 0>} : (i1) -> !eco.value 
        "eco.return"(%23) {_operand_types = [!eco.value]} : (!eco.value) -> () 
  }) {eco.shadow_roots, function_type = () -> (!eco.value), sym_name = "Bin_main_$_0", sym_visibility = "private"} : () -> () 
  "func.func"() ({
      ^bb0(%p: !eco.value):
        %2 = "eco.constant"() {kind = 2 : i32} : () -> !eco.value 
        %3 = "eco.constant.null_cons"() {tag = 1} : () -> !eco.value 
        %4 = "eco.project.record"(%p) {_operand_types = [!eco.value], field_index = 1} : (!eco.value) -> i64 
        %5 = "eco.construct.custom"(%3, %4) {_operand_types = [!eco.value, i64], constructor = "U16", size = 2, slot_kinds = array<i8: 0, 1>, tag = 4} : (!eco.value, i64) -> !eco.value 
        %6 = "eco.construct.list"(%5, %2) {_operand_types = [!eco.value, !eco.value], head_kind = 0, head_unboxed = false} : (!eco.value, !eco.value) -> !eco.value 
        %7 = "eco.constant.null_cons"() {tag = 1} : () -> !eco.value 
        %8 = "eco.project.record"(%p) {_operand_types = [!eco.value], field_index = 0} : (!eco.value) -> i64 
        %9 = "eco.construct.custom"(%7, %8) {_operand_types = [!eco.value, i64], constructor = "U16", size = 2, slot_kinds = array<i8: 0, 1>, tag = 4} : (!eco.value, i64) -> !eco.value 
        %10 = "eco.construct.list"(%9, %6) {_operand_types = [!eco.value, !eco.value], head_kind = 0, head_unboxed = false} : (!eco.value, !eco.value) -> !eco.value 
        %11 = "arith.constant"() {value = 1 : i64} : () -> i64 
        %12 = "eco.construct.custom"(%11) {_operand_types = [i64], constructor = "U8", size = 1, slot_kinds = array<i8: 1>, tag = 3} : (i64) -> !eco.value 
        %1 = "eco.construct.list"(%12, %10) {_operand_types = [!eco.value, !eco.value], head_kind = 0, head_unboxed = false} : (!eco.value, !eco.value) -> !eco.value 
        %14 = "arith.constant"() {value = 0 : i64} : () -> i64 
        %15 = "eco.call"(%14, %1) <{_operand_types = [i64, !eco.value], callee = @Bytes_Encode_getWidths_$_17}> : (i64, !eco.value) -> i64 
        %16 = "eco.construct.custom"(%15, %1) {_operand_types = [i64, !eco.value], constructor = "Seq", size = 2, slot_kinds = array<i8: 1, 0>, tag = 8} : (i64, !eco.value) -> !eco.value 
        "eco.return"(%16) {_operand_types = [!eco.value]} : (!eco.value) -> () 
  }) {eco.logical_param_types = ["record:2:i:i"], eco.logical_result_types = ["value"], function_type = (!eco.value) -> (!eco.value), sym_name = "Bin_encodePoint_$_1", sym_visibility = "private"} : () -> () 
  "eco.global"() {sym_name = "__eco_caf$Bin_decodePoint_$_2"} : () -> () 
  "func.func"() ({
        %0 = "eco.papCreate"() {arity = 3, function = @Bin_lambda_2, num_captured = 0} : () -> !eco.value 
        %1 = "eco.call"() <{callee = @Bytes_Decode_unsignedInt8_$_7}> : () -> !eco.value 
        %6 = "eco.constant.null_cons"() {tag = 1} : () -> !eco.value 
        %8 = "eco.papCreate"() {arity = 3, function = @Elm_Kernel_Bytes_read_u16, num_captured = 0} : () -> !eco.value 
        %9 = "eco.constant.null_cons"() {tag = 0} : () -> !eco.value 
        %10 = "eco.value.eq"(%6, %9) {_operand_types = [!eco.value, !eco.value]} : (!eco.value, !eco.value) -> i1 
        %11 = "eco.box"(%10) {_operand_types = [i1]} : (i1) -> !eco.value 
        %12 = "eco.papExtend"(%8, %11) {_operand_types = [!eco.value, !eco.value], remaining_arity = 3, slot_kinds = array<i8: 0>} : (!eco.value, !eco.value) -> !eco.value 
        %2 = "eco.construct.custom"(%12) {_operand_types = [!eco.value], constructor = "Decoder", size = 1, slot_kinds = array<i8: 0>, tag = 0} : (!eco.value) -> !eco.value 
        %14 = "eco.constant.null_cons"() {tag = 1} : () -> !eco.value 
        %16 = "eco.papCreate"() {arity = 3, function = @Elm_Kernel_Bytes_read_u16, num_captured = 0} : () -> !eco.value 
        %17 = "eco.constant.null_cons"() {tag = 0} : () -> !eco.value 
        %18 = "eco.value.eq"(%14, %17) {_operand_types = [!eco.value, !eco.value]} : (!eco.value, !eco.value) -> i1 
        %19 = "eco.box"(%18) {_operand_types = [i1]} : (i1) -> !eco.value 
        %20 = "eco.papExtend"(%16, %19) {_operand_types = [!eco.value, !eco.value], remaining_arity = 3, slot_kinds = array<i8: 0>} : (!eco.value, !eco.value) -> !eco.value 
        %3 = "eco.construct.custom"(%20) {_operand_types = [!eco.value], constructor = "Decoder", size = 1, slot_kinds = array<i8: 0>, tag = 0} : (!eco.value) -> !eco.value 
        %22 = "eco.project.custom"(%1) {_operand_types = [!eco.value], field_index = 0} : (!eco.value) -> !eco.value 
        %23 = "eco.project.custom"(%2) {_operand_types = [!eco.value], field_index = 0} : (!eco.value) -> !eco.value 
        %24 = "eco.project.custom"(%3) {_operand_types = [!eco.value], field_index = 0} : (!eco.value) -> !eco.value 
        %25 = "eco.papCreate"(%22, %23, %24, %0) {_fast_evaluator = @Bin_lambda_10$cap, _operand_types = [!eco.value, !eco.value, !eco.value, !eco.value], arity = 6, function = @Bin_lambda_10$clo, num_captured = 4, slot_kinds = array<i8: 0, 0, 0, 0>} : (!eco.value, !eco.value, !eco.value, !eco.value) -> !eco.value 
        %26 = "eco.construct.custom"(%25) {_operand_types = [!eco.value], constructor = "Decoder", size = 1, slot_kinds = array<i8: 0>, tag = 0} : (!eco.value) -> !eco.value 
        "eco.return"(%26) {_operand_types = [!eco.value]} : (!eco.value) -> () 
  }) {eco.caf_memo, function_type = () -> (!eco.value), sym_name = "Bin_decodePoint_$_2", sym_visibility = "private"} : () -> () 
  "func.func"() ({
      ^bb0(%_v0: !eco.value, %bs: !eco.value):
        %2 = "eco.project.custom"(%_v0) {_operand_types = [!eco.value], field_index = 0} : (!eco.value) -> !eco.value 
        %3 = "eco.call"(%2, %bs) <{_operand_types = [!eco.value, !eco.value], callee = @Elm_Kernel_Bytes_decode}> : (!eco.value, !eco.value) -> !eco.value 
        "eco.return"(%3) {_operand_types = [!eco.value]} : (!eco.value) -> () 
  }) {eco.logical_param_types = ["custom:0:1:v", "value"], eco.logical_result_types = ["value"], function_type = (!eco.value, !eco.value) -> (!eco.value), sym_name = "Bytes_Decode_decode_$_3", sym_visibility = "private"} : () -> () 
  "eco.global"() {sym_name = "__eco_caf$Bytes_Decode_unsignedInt8_$_7"} : () -> () 
  "func.func"() ({
        %0 = "eco.papCreate"() {arity = 2, function = @Elm_Kernel_Bytes_read_u8, num_captured = 0} : () -> !eco.value 
        %1 = "eco.construct.custom"(%0) {_operand_types = [!eco.value], constructor = "Decoder", size = 1, slot_kinds = array<i8: 0>, tag = 0} : (!eco.value) -> !eco.value 
        "eco.return"(%1) {_operand_types = [!eco.value]} : (!eco.value) -> () 
  }) {eco.caf_memo, function_type = () -> (!eco.value), sym_name = "Bytes_Decode_unsignedInt8_$_7", sym_visibility = "private"} : () -> () 
  "func.func"() ({
        %2 = "eco.constant.null_cons"() {tag = 1} : () -> !eco.value 
        "eco.return"(%2) {_operand_types = [!eco.value]} : (!eco.value) -> () 
  }) {eco.logical_param_types = [], eco.logical_result_types = ["value"], function_type = () -> (!eco.value), sym_name = "Bytes_BE_$_8", sym_visibility = "private"} : () -> () 
  "func.func"() ({
      ^bb0(%arg0: !eco.value):
        %1 = "eco.construct.custom"(%arg0) {_operand_types = [!eco.value], constructor = "Decoder", size = 1, slot_kinds = array<i8: 0>, tag = 0} : (!eco.value) -> !eco.value 
        "eco.return"(%1) {_operand_types = [!eco.value]} : (!eco.value) -> () 
  }) {eco.logical_param_types = [], eco.logical_result_types = ["custom:0:1:v"], function_type = (!eco.value) -> (!eco.value), sym_name = "Bytes_Decode_Decoder_$_11", sym_visibility = "private"} : () -> () 
  "func.func"() ({
        %2 = "eco.constant.null_cons"() {tag = 0} : () -> !eco.value 
        "eco.return"(%2) {_operand_types = [!eco.value]} : (!eco.value) -> () 
  }) {eco.logical_param_types = [], eco.logical_result_types = ["value"], function_type = () -> (!eco.value), sym_name = "Bytes_LE_$_12", sym_visibility = "private"} : () -> () 
  "func.func"() ({
      ^bb0(%arg0: !eco.value):
        %1 = "eco.construct.custom"(%arg0) {_operand_types = [!eco.value], constructor = "Decoder", size = 1, slot_kinds = array<i8: 0>, tag = 0} : (!eco.value) -> !eco.value 
        "eco.return"(%1) {_operand_types = [!eco.value]} : (!eco.value) -> () 
  }) {eco.logical_param_types = [], eco.logical_result_types = ["custom:0:1:v"], function_type = (!eco.value) -> (!eco.value), sym_name = "Bytes_Decode_Decoder_$_13", sym_visibility = "private"} : () -> () 
  "func.func"() ({
      ^bb0(%arg0: i64):
        %1 = "eco.construct.custom"(%arg0) {_operand_types = [i64], constructor = "U8", size = 1, slot_kinds = array<i8: 1>, tag = 3} : (i64) -> !eco.value 
        "eco.return"(%1) {_operand_types = [!eco.value]} : (!eco.value) -> () 
  }) {eco.logical_param_types = [], eco.logical_result_types = ["value"], function_type = (i64) -> (!eco.value), sym_name = "Bytes_Encode_U8_$_14", sym_visibility = "private"} : () -> () 
  "func.func"() ({
      ^bb0(%arg0: !eco.value, %arg1: i64):
        %2 = "eco.construct.custom"(%arg0, %arg1) {_operand_types = [!eco.value, i64], constructor = "U16", size = 2, slot_kinds = array<i8: 0, 1>, tag = 4} : (!eco.value, i64) -> !eco.value 
        "eco.return"(%2) {_operand_types = [!eco.value]} : (!eco.value) -> () 
  }) {eco.logical_param_types = [], eco.logical_result_types = ["value"], function_type = (!eco.value, i64) -> (!eco.value), sym_name = "Bytes_Encode_U16_$_15", sym_visibility = "private"} : () -> () 
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
                    %24 = "eco.call"(%22) <{_operand_types = [!eco.value], callee = @Bytes_Encode_getWidth_$_19}> : (!eco.value) -> i64 
                    %25 = "eco.int.add"(%14, %24) {_operand_types = [i64, i64]} : (i64, i64) -> i64 
                    %26 = "arith.constant"() {value = false} : () -> i1 
                    %27 = "arith.constant"() {value = 0 : i64} : () -> i64 
                    "eco.yield"(%25, %23, %26, %27) {_operand_types = [i64, !eco.value, i1, i64]} : (i64, !eco.value, i1, i64) -> () 
              }) {_operand_types = [i1], case_kind = "bool", tags = array<i64: 1, 0>} : (i1) -> (i64, !eco.value, i1, i64) 
              "scf.yield"(%28, %29, %30, %31) {_operand_types = [i64, !eco.value, i1, i64]} : (i64, !eco.value, i1, i64) -> () 
        }) {_operand_types = [i64, !eco.value, i1, i64]} : (i64, !eco.value, i1, i64) -> (i64, !eco.value, i1, i64) 
        "eco.return"(%7) {_operand_types = [i64]} : (i64) -> () 
  }) {eco.logical_param_types = ["i64", "cons:v:v"], eco.logical_result_types = ["i64"], function_type = (i64, !eco.value) -> (i64), sym_name = "Bytes_Encode_getWidths_$_17", sym_visibility = "private"} : () -> () 
  "func.func"() ({
      ^bb0(%arg0: i64, %arg1: !eco.value):
        %2 = "eco.construct.custom"(%arg0, %arg1) {_operand_types = [i64, !eco.value], constructor = "Seq", size = 2, slot_kinds = array<i8: 1, 0>, tag = 8} : (i64, !eco.value) -> !eco.value 
        "eco.return"(%2) {_operand_types = [!eco.value]} : (!eco.value) -> () 
  }) {eco.logical_param_types = [], eco.logical_result_types = ["value"], function_type = (i64, !eco.value) -> (!eco.value), sym_name = "Bytes_Encode_Seq_$_18", sym_visibility = "private"} : () -> () 
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
  }) {eco.logical_param_types = ["value"], eco.logical_result_types = ["i64"], function_type = (!eco.value) -> (i64), sym_name = "Bytes_Encode_getWidth_$_19", sym_visibility = "private"} : () -> () 
  "func.func"() ({
      ^bb0(%mono_inline_18: !eco.value, %mono_inline_17: !eco.value, %mono_inline_16: !eco.value, %mono_inline_3: !eco.value, %bites: !eco.value, %offset: i64):
        %16 = "eco.papExtend"(%mono_inline_18, %bites, %offset) {_call_kind = "segmentation_unknown", _operand_types = [!eco.value, !eco.value, i64], slot_kinds = array<i8: 0, 1>} : (!eco.value, !eco.value, i64) -> !eco.value 
        %19 = "eco.project.tuple2"(%16) {_operand_types = [!eco.value], field = 0} : (!eco.value) -> i64 
        %21 = "eco.project.tuple2"(%16) {_operand_types = [!eco.value], field = 1} : (!eco.value) -> i64 
        %22 = "eco.papExtend"(%mono_inline_17, %bites, %19) {_call_kind = "segmentation_unknown", _operand_types = [!eco.value, !eco.value, i64], slot_kinds = array<i8: 0, 1>} : (!eco.value, !eco.value, i64) -> !eco.value 
        %25 = "eco.project.tuple2"(%22) {_operand_types = [!eco.value], field = 0} : (!eco.value) -> i64 
        %27 = "eco.project.tuple2"(%22) {_operand_types = [!eco.value], field = 1} : (!eco.value) -> i64 
        %28 = "eco.papExtend"(%mono_inline_16, %bites, %25) {_call_kind = "segmentation_unknown", _operand_types = [!eco.value, !eco.value, i64], slot_kinds = array<i8: 0, 1>} : (!eco.value, !eco.value, i64) -> !eco.value 
        %31 = "eco.project.tuple2"(%28) {_operand_types = [!eco.value], field = 0} : (!eco.value) -> i64 
        %33 = "eco.project.tuple2"(%28) {_operand_types = [!eco.value], field = 1} : (!eco.value) -> i64 
        %34 = "eco.papExtend"(%mono_inline_3, %21, %27, %33) {_call_kind = "singleton_fast", _capture_abi = [], _fast_evaluator = @Bin_lambda_2, _operand_types = [!eco.value, i64, i64, i64], remaining_arity = 3, slot_kinds = array<i8: 1, 1, 1>} : (!eco.value, i64, i64, i64) -> !eco.value 
        %35 = "eco.construct.tuple2"(%31, %34) {_operand_types = [i64, !eco.value], unboxed_bitmap = 1} : (i64, !eco.value) -> !eco.value 
        "eco.return"(%35) {_operand_types = [!eco.value]} : (!eco.value) -> () 
  }) {eco.logical_param_types = ["value", "value", "value", "value", "value", "i64"], eco.logical_result_types = ["tuple2:i:v"], function_type = (!eco.value, !eco.value, !eco.value, !eco.value, !eco.value, i64) -> (!eco.value), sym_name = "Bin_lambda_10$cap", sym_visibility = "private"} : () -> () 
  "func.func"() ({
      ^bb0(%closure: !eco.value, %bites: !eco.value, %offset: i64):
        %3 = "eco.project.closure"(%closure) {index = 0, is_unboxed = false} : (!eco.value) -> !eco.value 
        %4 = "eco.project.closure"(%closure) {index = 1, is_unboxed = false} : (!eco.value) -> !eco.value 
        %5 = "eco.project.closure"(%closure) {index = 2, is_unboxed = false} : (!eco.value) -> !eco.value 
        %6 = "eco.project.closure"(%closure) {index = 3, is_unboxed = false} : (!eco.value) -> !eco.value 
        %7 = "eco.call"(%3, %4, %5, %6, %bites, %offset) <{_operand_types = [!eco.value, !eco.value, !eco.value, !eco.value, !eco.value, i64], callee = @Bin_lambda_10$cap}> : (!eco.value, !eco.value, !eco.value, !eco.value, !eco.value, i64) -> !eco.value 
        "eco.return"(%7) {_operand_types = [!eco.value]} : (!eco.value) -> () 
  }) {eco.logical_param_types = ["value", "value", "i64"], eco.logical_result_types = ["tuple2:i:v"], function_type = (!eco.value, !eco.value, i64) -> (!eco.value), sym_name = "Bin_lambda_10$clo", sym_visibility = "private"} : () -> () 
  "func.func"() ({
      ^bb0(%_v0: i64, %x: i64, %y: i64):
        %10 = "eco.construct.record"(%x, %y) {_operand_types = [i64, i64], field_count = 2, slot_kinds = array<i8: 1, 1>} : (i64, i64) -> !eco.value 
        "eco.return"(%10) {_operand_types = [!eco.value]} : (!eco.value) -> () 
  }) {eco.logical_param_types = ["i64", "i64", "i64"], eco.logical_result_types = ["record:2:i:i"], function_type = (i64, i64, i64) -> (!eco.value), sym_name = "Bin_lambda_2", sym_visibility = "private"} : () -> () 
  "func.func"() ({
        %0 = "eco.call"() <{callee = @Bin_main_$_0}> : () -> !eco.value 
        "eco.return"(%0) {_operand_types = [!eco.value]} : (!eco.value) -> () 
  }) {eco.list_chunks, function_type = () -> (!eco.value), sym_name = "main", sym_visibility = "private"} : () -> () 
  "func.func"() ({
      ^bb0(%arg0: !eco.value, %arg1: !eco.value):
        %2 = "eco.constant"() {kind = 2 : i32} : () -> !eco.value 
        "eco.return"(%2) {_operand_types = [!eco.value]} : (!eco.value) -> () 
  }) {eco.logical_param_types = ["value", "value"], eco.logical_result_types = ["value"], function_type = (!eco.value, !eco.value) -> (!eco.value), is_kernel = true, sym_name = "Elm_Kernel_Bytes_decode", sym_visibility = "private"} : () -> () 
  "func.func"() ({
      ^bb0(%arg0: !eco.value):
        %1 = "eco.constant"() {kind = 2 : i32} : () -> !eco.value 
        "eco.return"(%1) {_operand_types = [!eco.value]} : (!eco.value) -> () 
  }) {eco.logical_param_types = ["value"], eco.logical_result_types = ["value"], function_type = (!eco.value) -> (!eco.value), is_kernel = true, sym_name = "Elm_Kernel_Bytes_encode", sym_visibility = "private"} : () -> () 
  "func.func"() ({
      ^bb0(%arg0: !eco.value, %arg1: !eco.value, %arg2: i64):
        %3 = "eco.constant"() {kind = 2 : i32} : () -> !eco.value 
        "eco.return"(%3) {_operand_types = [!eco.value]} : (!eco.value) -> () 
  }) {eco.logical_param_types = ["value", "value", "i64"], eco.logical_result_types = ["value"], function_type = (!eco.value, !eco.value, i64) -> (!eco.value), is_kernel = true, sym_name = "Elm_Kernel_Bytes_read_u16", sym_visibility = "private"} : () -> () 
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
  }) {eco.logical_param_types = ["value"], eco.logical_result_types = ["value"], function_type = (!eco.value) -> (!eco.value), is_kernel = true, sym_name = "Elm_Kernel_VirtualDom_text", sym_visibility = "private"} : () -> () 
  "eco.type_table"() {ctors = [[0, 2, 2, 0], [0, 3, 2, 0], [1, 4, 2, 0], [0, 5, 2, 1], [1, 7, 3, 2], [2, 9, 5, 2], [3, 10, 7, 1], [4, 11, 8, 2], [5, 12, 10, 2], [6, 13, 12, 2], [7, 14, 14, 2], [8, 15, 16, 2], [9, 16, 18, 2], [10, 2, 20, 1], [0, 17, 23, 1], [0, 17, 26, 1]], fields = [[0, 0], [1, 0], [6, 0], [6, 5], [8, 0], [6, 5], [8, 0], [6, 0], [6, 5], [8, 0], [6, 5], [8, 0], [6, 5], [8, 4], [6, 5], [8, 4], [6, 0], [8, 7], [6, 0], [8, 3], [6, 2], [0, 0], [0, 1], [6, 10], [0, 0], [0, 0], [6, 14]], func_args = [0, 2, 0, 2], strings = ["x", "y", "Bytes", "LE", "BE", "I8", "field0", "I16", "field1", "I32", "U8", "U16", "U32", "F32", "F64", "Seq", "Utf8", "Decoder"], types = [[0, 0, 0], [1, 3, 0, 2], [2, 4, 0, 1], [3, 0, 4], [4, 0, 1], [5, 4, 1, 2], [6, 4, 3, 11], [7, 1, 6], [8, 2, 2, 21, 2], [9, 5, 0, 1, 8], [10, 5, 1, 1, 9], [11, 4, 14, 1], [12, 2, 2, 24, 2], [13, 5, 2, 1, 12], [14, 5, 3, 1, 13], [15, 4, 15, 1]]} : () -> () 
} 
