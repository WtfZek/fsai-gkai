<template>
  <div class="mobile-user-profile container">
    <div class="content">
      <van-form v-if="isLogin">
        <div class="avatar">
          <van-image :src="fileList[0].url" size="80" width="80" fit="cover" round />
          <!--          <van-uploader v-model="fileList"-->
          <!--                        reupload max-count="1"-->
          <!--                        :deletable="false"-->
          <!--                        :after-read="afterRead"/>-->
        </div>
        <van-cell-group inset v-model="form">
          <van-field v-model="form.username" label="账号" readonly />
          <van-field v-model="form.nickname" label="昵称" readonly />

          <van-field label="算力">
            <template #input>
              <van-tag type="primary">{{ form.power }}</van-tag>
            </template>
          </van-field>

          <van-field label="有效期" v-if="form.expired_time > 0">
            <template #input>
              {{ dateFormat(form.expired_time) }}
            </template>
          </van-field>
        </van-cell-group>
      </van-form>

      <div class="opt" v-if="isLogin">
        <van-row :gutter="10">
          <van-col :span="8">
            <van-button round block @click="showPasswordDialog = true" size="small">修改密码</van-button>
          </van-col>
          <van-col :span="8">
            <van-button round block @click="logout" size="small">退出登录</van-button>
          </van-col>

          <van-col :span="8">
            <van-button round block @click="showSettings = true" icon="setting" size="small">设置</van-button>
          </van-col>
        </van-row>
      </div>

      <div class="product-list">
        <h3>充值套餐</h3>
        <div class="item" v-for="item in products" :key="item.id">
          <div class="title">
            <span class="name">{{ item.name }}</span>
            <div class="pay-btn">
              <div v-for="payWay in payWays" @click="pay(item, payWay)" :key="payWay">
                <span>
                  <van-button type="primary" size="small" v-if="payWay.pay_type === 'alipay'"> <i class="iconfont icon-alipay"></i> 支付宝 </van-button>
                  <van-button type="success" size="small" v-if="payWay.pay_type === 'wxpay'"> <i class="iconfont icon-wechat-pay"></i> 微信支付 </van-button>
                </span>
              </div>
            </div>
          </div>

          <van-cell-group>
            <van-cell title="商品价格">
              <span class="price"> ￥{{ item.discount }} </span>
              （
              <del>￥{{ item.price }}</del>
              ）
            </van-cell>
            <van-cell title="有效期">
              <span v-if="item.days > 0">{{ item.days }}天</span>
              <van-tag type="primary" v-else>长期有效</van-tag>
            </van-cell>
            <van-cell title="算力值">
              <span v-if="item.power > 0">{{ item.power }}</span>
              <span v-else>{{ vipMonthPower }}</span>
            </van-cell>
          </van-cell-group>
        </div>
      </div>
    </div>

    <van-dialog
      v-model:show="showPasswordDialog"
      title="修改密码"
      show-cancel-button
      @confirm="updatePass"
      @cancel="showPasswordDialog = false"
      :before-close="beforeClose"
    >
      <van-form>
        <van-cell-group inset>
          <van-field v-model="pass.old" placeholder="旧密码" />
          <van-field v-model="pass.new" type="password" placeholder="新密码" />
          <van-field v-model="pass.renew" type="password" placeholder="确认密码" />
        </van-cell-group>
      </van-form>
    </van-dialog>

    <van-action-sheet v-model:show="showSettings" title="用户设置">
      <div class="setting-content">
        <van-form>
          <van-cell-group inset>
            <van-field name="switch" label="暗黑主题">
              <template #input>
                <van-switch v-model="dark" @change="(val) => store.setTheme(val ? 'dark' : 'light')" />
              </template>
            </van-field>

            <van-field name="switch" label="流式输出">
              <template #input>
                <van-switch v-model="stream" @change="(val) => store.setChatStream(val)" />
              </template>
            </van-field>
            <!--            <van-field-->
            <!--                v-model="password"-->
            <!--                type="password"-->
            <!--                name="密码"-->
            <!--                label="密码"-->
            <!--                placeholder="密码"-->
            <!--                :rules="[{ required: true, message: '请填写密码' }]"-->
            <!--            />-->
          </van-cell-group>
          <!--          <div style="margin: 16px;">-->
          <!--            <van-button round block type="primary" native-type="submit">-->
          <!--              提交-->
          <!--            </van-button>-->
          <!--          </div>-->
        </van-form>
      </div>
    </van-action-sheet>
  </div>
</template>

<script setup>
import { onMounted, ref } from "vue";
import { showFailToast, showLoadingToast, showNotify, showSuccessToast } from "vant";
import { httpGet, httpPost } from "@/utils/http";
import { dateFormat, showLoginDialog } from "@/utils/libs";
import { ElMessage } from "element-plus";
import { checkSession, getSystemInfo } from "@/store/cache";
import { useRouter } from "vue-router";
import { removeUserToken } from "@/store/session";
import { useSharedStore } from "@/store/sharedata";

const form = ref({
  username: "GeekMaster",
  nickname: "飞速学长@001",
  mobile: "1300000000",
  avatar: "",
  power: 0,
});
const fileList = ref([
  {
    url: "/images/user-info.png",
    message: "上传中...",
  },
]);

const products = ref([]);
const vipMonthPower = ref(0);
const payWays = ref({});
const router = useRouter();
const userId = ref(0);
const isLogin = ref(false);
const showSettings = ref(false);
const store = useSharedStore();
const stream = ref(store.chatStream);
const dark = ref(store.theme === "dark");

onMounted(() => {
  checkSession()
    .then((user) => {
      userId.value = user.id;
      isLogin.value = true;
      httpGet("/api/user/profile")
        .then((res) => {
          form.value = res.data;
          fileList.value[0].url = form.value.avatar;
        })
        .catch((e) => {
          console.log(e.message);
          showFailToast("获取用户信息失败");
        });
    })
    .catch(() => {});

  // 获取产品列表
  httpGet("/api/product/list")
    .then((res) => {
      products.value = res.data;
    })
    .catch((e) => {
      showFailToast("获取产品套餐失败：" + e.message);
    });

  getSystemInfo()
    .then((res) => {
      vipMonthPower.value = res.data["vip_month_power"];
    })
    .catch((e) => {
      showFailToast("获取系统配置失败：" + e.message);
    });

  httpGet("/api/payment/payWays")
    .then((res) => {
      payWays.value = res.data;
    })
    .catch((e) => {
      ElMessage.error("获取支付方式失败：" + e.message);
    });
});

// const afterRead = (file) => {
//   file.status = 'uploading';
//   file.message = '上传中...';
//   // 压缩图片并上传
//   new Compressor(file.file, {
//     quality: 0.6,
//     success(result) {
//       const formData = new FormData();
//       formData.append('file', result, result.name);
//       // 执行上传操作
//       httpPost('/api/upload', formData).then((res) => {
//         form.value.avatar = res.data.url
//         file.status = 'success'
//         httpPost('/api/user/profile/update', form.value).then(() => {
//           showSuccessToast('上传成功')
//         }).catch(() => {
//           showFailToast('上传失败')
//         })
//       }).catch((e) => {
//         showNotify({type: 'danger', message: '上传失败：' + e.message})
//       })
//     },
//     error(err) {
//       console.log(err.message);
//     },
//   });
// }

const showPasswordDialog = ref(false);
const pass = ref({
  old: "",
  new: "",
  renew: "",
});

const beforeClose = (action) => {
  new Promise((resolve) => {
    resolve(action === "confirm");
  });
};

// 提交修改密码
const updatePass = () => {
  if (pass.value.old === "") {
    return showNotify({ type: "danger", message: "请输入旧密码" });
  }
  if (!pass.value.new || pass.value.new.length < 8) {
    return showNotify({ type: "danger", message: "密码的长度为8-16个字符" });
  }
  if (pass.value.renew !== pass.value.new) {
    return showNotify({ type: "danger", message: "两次输入密码不一致" });
  }
  httpPost("/api/user/password", {
    old_pass: pass.value.old,
    password: pass.value.new,
    repass: pass.value.renew,
  })
    .then(() => {
      showSuccessToast("更新成功！");
      showPasswordDialog.value = false;
    })
    .catch((e) => {
      showFailToast("更新失败，" + e.message);
      showPasswordDialog.value = false;
    });
};

const pay = (product, payWay) => {
  if (!isLogin.value) {
    return showLoginDialog(router);
  }

  showLoadingToast({
    message: "正在创建订单",
    forbidClick: true,
  });
  let host = process.env.VUE_APP_API_HOST;
  if (host === "") {
    host = `${location.protocol}//${location.host}`;
  }
  httpPost(`${process.env.VUE_APP_API_HOST}/api/payment/doPay`, {
    product_id: product.id,
    pay_way: payWay.pay_way,
    pay_type: payWay.pay_type,
    user_id: userId.value,
    host: host,
    device: "wechat",
  })
    .then((res) => {
      location.href = res.data;
    })
    .catch((e) => {
      showFailToast("生成支付订单失败：" + e.message);
    });
};

const logout = function () {
  httpGet("/api/user/logout")
    .then(() => {
      removeUserToken();
      store.setIsLogin(false);
      router.push("/");
    })
    .catch(() => {
      showFailToast("注销失败！");
    });
};
</script>

<style lang="stylus">
.mobile-user-profile {
  .content {
    padding-top 15px
    padding-bottom 60px

    .avatar {
      display flex
      justify-content center

      .van-image {
        border-radius 50%
      }
    }

    .van-field__label {
      width 100px
      text-align right
    }

    .opt {
      padding 10px 15px
    }

    .product-list {
      padding 0 15px

      color var(--van-text-color)

      .item {
        border 1px solid var(--van-border-color)
        border-radius 10px
        margin-bottom 15px
        overflow hidden

        .title {
          padding 12px
          position relative

          .name {
            font-size 16px
            font-weight 700
          }

          .pay-btn {
            position absolute
            top 5px
            right 10px
            display flex

            .van-button {
              font-size 14px
              margin-left 10px
            }
          }
        }

        .van-cell__value {
          flex 2
        }

        .price {
          font-size 18px
          color #f56c6c
        }
      }
    }
  }

  .setting-content {
    padding 16px
  }
}
</style>
