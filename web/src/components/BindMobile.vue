<template>
  <el-dialog
      v-model="showDialog"
      :close-on-click-modal="true"
      style="max-width: 400px"
      @close="close"
      :title="title"
  >
    <div class="form">
      <div class="text-center" v-if="mobile !== ''">当前已绑手机号：{{ mobile }}</div>

      <el-form label-position="top">
        <el-form-item label="手机号">
          <el-input v-model="form.mobile"/>
        </el-form-item>
        <el-form-item label="验证码">
          <el-row :gutter="0">
            <el-col :span="16">
              <el-input v-model="form.code" maxlength="6"/>
            </el-col>
            <el-col :span="8" style="padding-left: 10px">
              <send-msg :receiver="form.mobile" size="default" type="mobile"/>
            </el-col>
          </el-row>
        </el-form-item>
      </el-form>
    </div>

    <template #footer>
      <span class="dialog-footer">
        <el-button type="primary" @click="save">
          提交绑定
        </el-button>
      </span>
    </template>
  </el-dialog>
</template>

<script setup>
import {computed, ref, watch} from "vue";
import SendMsg from "@/components/SendMsg.vue";
import {ElMessage} from "element-plus";
import {httpPost} from "@/utils/http";
import {checkSession} from "@/store/cache";

const props = defineProps({
  show: Boolean,
});

const showDialog = computed(() => {
  return props.show
})

const title = ref('绑定手机')
const mobile = ref('')
const form = ref({
  mobile: '',
  code: ''
})

watch(showDialog, (val) => {
  if (val) {
    form.value = {
      mobile: '',
      code: ''
    }

    checkSession().then(user => {
      mobile.value = user.mobile
    })
  }
})

const emits = defineEmits(['hide']);

const save = () => {
  if (form.value.code === '') {
    return ElMessage.error("请输入验证码");
  }

  httpPost('/api/user/bind/mobile', form.value).then(() => {
    ElMessage.success("绑定成功")
    emits('hide')
  }).catch(e => {
    ElMessage.error("绑定失败：" + e.message);
  })
}

const close = function () {
  emits('hide');
}
</script>

<style lang="stylus" scoped>
.form {
  .text-center {
    text-align center
    padding-bottom 15px
    font-size 14px
    color #a1a1a1
    font-weight 700
  }

  .el-form-item__content {
    .el-row {
      width 100%
    }
  }
}
</style>