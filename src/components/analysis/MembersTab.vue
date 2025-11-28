<script setup lang="ts">
import { computed, ref, watch } from 'vue'
import type {
  MemberActivity,
  MemberNameHistory,
  RepeatAnalysis,
  CatchphraseAnalysis,
  DragonKingAnalysis,
  MonologueAnalysis,
} from '@/types/chat'
import { RankListPro, BarChart, ListPro } from '@/components/charts'
import type { RankItem, BarChartData } from '@/components/charts'
import LoadingState from '@/components/UI/LoadingState.vue'

interface TimeFilter {
  startTs?: number
  endTs?: number
}

const props = defineProps<{
  sessionId: string
  memberActivity: MemberActivity[]
  timeFilter?: TimeFilter
}>()

// ==================== 龙王分析 ====================
const dragonKingAnalysis = ref<DragonKingAnalysis | null>(null)
const isLoadingDragonKing = ref(false)

// 加载龙王分析数据
async function loadDragonKingAnalysis() {
  if (!props.sessionId) return

  isLoadingDragonKing.value = true
  try {
    dragonKingAnalysis.value = await window.chatApi.getDragonKingAnalysis(props.sessionId, props.timeFilter)
  } catch (error) {
    console.error('加载龙王分析失败:', error)
  } finally {
    isLoadingDragonKing.value = false
  }
}

// 龙王排行数据
const dragonKingRankData = computed<RankItem[]>(() => {
  if (!dragonKingAnalysis.value) return []
  return dragonKingAnalysis.value.rank.map((m) => ({
    id: m.memberId.toString(),
    name: m.name,
    value: m.count,
    percentage: m.percentage,
  }))
})

// ==================== 自言自语分析 ====================
const monologueAnalysis = ref<MonologueAnalysis | null>(null)
const isLoadingMonologue = ref(false)

// 加载自言自语分析数据
async function loadMonologueAnalysis() {
  if (!props.sessionId) return

  isLoadingMonologue.value = true
  try {
    monologueAnalysis.value = await window.chatApi.getMonologueAnalysis(props.sessionId, props.timeFilter)
  } catch (error) {
    console.error('加载自言自语分析失败:', error)
  } finally {
    isLoadingMonologue.value = false
  }
}

// 格式化日期
function formatDateTime(ts: number): string {
  const date = new Date(ts * 1000)
  const year = date.getFullYear()
  const month = String(date.getMonth() + 1).padStart(2, '0')
  const day = String(date.getDate()).padStart(2, '0')
  const hour = String(date.getHours()).padStart(2, '0')
  const minute = String(date.getMinutes()).padStart(2, '0')
  return `${year}-${month}-${day} ${hour}:${minute}`
}

// 获取连击等级标签
function getComboLabel(maxCombo: number): { text: string; color: string } {
  if (maxCombo >= 10) return { text: '无人区广播', color: 'text-red-600 dark:text-red-400' }
  if (maxCombo >= 5) return { text: '小作文达人', color: 'text-yellow-600 dark:text-yellow-400' }
  return { text: '加特林模式', color: 'text-green-600 dark:text-green-400' }
}

// 获取第一名的总连击数（作为百分比基数）
const maxTotalStreaks = computed(() => {
  if (!monologueAnalysis.value || monologueAnalysis.value.rank.length === 0) return 1
  return monologueAnalysis.value.rank[0].totalStreaks
})

// ==================== 复读分析 ====================
const repeatAnalysis = ref<RepeatAnalysis | null>(null)
const isLoadingRepeat = ref(false)

// 复读排行榜显示模式：count（绝对次数）或 rate（复读率）
const repeatRankMode = ref<'count' | 'rate'>('rate')

// 转换复读数据为排行榜格式
const originatorRankData = computed<RankItem[]>(() => {
  if (!repeatAnalysis.value) return []
  const data =
    repeatRankMode.value === 'count' ? repeatAnalysis.value.originators : repeatAnalysis.value.originatorRates
  return data.map((m) => ({
    id: m.memberId.toString(),
    name: m.name,
    value: (m as any).count,
    percentage: repeatRankMode.value === 'count' ? (m as any).percentage : (m as any).rate,
  }))
})

const initiatorRankData = computed<RankItem[]>(() => {
  if (!repeatAnalysis.value) return []
  const data = repeatRankMode.value === 'count' ? repeatAnalysis.value.initiators : repeatAnalysis.value.initiatorRates
  return data.map((m) => ({
    id: m.memberId.toString(),
    name: m.name,
    value: (m as any).count,
    percentage: repeatRankMode.value === 'count' ? (m as any).percentage : (m as any).rate,
  }))
})

const breakerRankData = computed<RankItem[]>(() => {
  if (!repeatAnalysis.value) return []
  const data = repeatRankMode.value === 'count' ? repeatAnalysis.value.breakers : repeatAnalysis.value.breakerRates
  return data.map((m) => ({
    id: m.memberId.toString(),
    name: m.name,
    value: (m as any).count,
    percentage: repeatRankMode.value === 'count' ? (m as any).percentage : (m as any).rate,
  }))
})

// 复读链长度分布图表数据
const chainLengthChartData = computed<BarChartData>(() => {
  if (!repeatAnalysis.value) return { labels: [], values: [] }
  const distribution = repeatAnalysis.value.chainLengthDistribution
  return {
    labels: distribution.map((d) => `${d.length}人`),
    values: distribution.map((d) => d.count),
  }
})

// 加载复读分析数据
async function loadRepeatAnalysis() {
  if (!props.sessionId) return

  isLoadingRepeat.value = true
  try {
    repeatAnalysis.value = await window.chatApi.getRepeatAnalysis(props.sessionId, props.timeFilter)
  } catch (error) {
    console.error('加载复读分析失败:', error)
  } finally {
    isLoadingRepeat.value = false
  }
}

// 截断过长的复读内容
function truncateContent(content: string, maxLength = 30): string {
  if (content.length <= maxLength) return content
  return content.slice(0, maxLength) + '...'
}

// 格式化日期
function formatDate(ts: number): string {
  const date = new Date(ts * 1000)
  const year = date.getFullYear()
  const month = String(date.getMonth() + 1).padStart(2, '0')
  const day = String(date.getDate()).padStart(2, '0')
  return `${year}-${month}-${day}`
}

// ==================== 口头禅分析 ====================
const catchphraseAnalysis = ref<CatchphraseAnalysis | null>(null)
const isLoadingCatchphrase = ref(false)

// 加载口头禅分析数据
async function loadCatchphraseAnalysis() {
  if (!props.sessionId) return

  isLoadingCatchphrase.value = true
  try {
    catchphraseAnalysis.value = await window.chatApi.getCatchphraseAnalysis(props.sessionId, props.timeFilter)
  } catch (error) {
    console.error('加载口头禅分析失败:', error)
  } finally {
    isLoadingCatchphrase.value = false
  }
}

// 成员活跃度排行数据
const memberRankData = computed<RankItem[]>(() => {
  return props.memberActivity.map((m) => ({
    id: m.memberId.toString(),
    name: m.name,
    value: m.messageCount,
    percentage: m.percentage,
  }))
})

// 昵称变更记录
interface MemberWithHistory {
  memberId: number
  name: string
  history: MemberNameHistory[]
}

const membersWithNicknameChanges = ref<MemberWithHistory[]>([])
const isLoadingHistory = ref(false)

// 加载有昵称变更的成员
async function loadMembersWithNicknameChanges() {
  if (!props.sessionId || props.memberActivity.length === 0) return

  isLoadingHistory.value = true
  const membersWithChanges: MemberWithHistory[] = []

  try {
    // 并发查询所有成员的历史昵称
    const historyPromises = props.memberActivity.map((member) =>
      window.chatApi.getMemberNameHistory(props.sessionId, member.memberId)
    )

    const allHistories = await Promise.all(historyPromises)

    // 筛选出有昵称变更的成员（历史记录 > 1）
    props.memberActivity.forEach((member, index) => {
      const history = allHistories[index]
      if (history.length > 1) {
        membersWithChanges.push({
          memberId: member.memberId,
          name: member.name,
          history,
        })
      }
    })

    membersWithNicknameChanges.value = membersWithChanges
  } catch (error) {
    console.error('加载昵称变更记录失败:', error)
  } finally {
    isLoadingHistory.value = false
  }
}

// 监听 sessionId 和 memberActivity 变化，重新加载昵称历史
watch(
  () => [props.sessionId, props.memberActivity.length],
  () => {
    loadMembersWithNicknameChanges()
  },
  { immediate: true }
)

// 监听 sessionId 和 timeFilter 变化，重新加载分析数据
watch(
  () => [props.sessionId, props.timeFilter],
  () => {
    loadDragonKingAnalysis()
    loadMonologueAnalysis()
    loadRepeatAnalysis()
    loadCatchphraseAnalysis()
  },
  { immediate: true, deep: true }
)

// 格式化时间段（用于横向展示）
function formatPeriod(startTs: number, endTs: number | null): string {
  const formatDate = (ts: number) => {
    const date = new Date(ts * 1000)
    const year = date.getFullYear()
    const month = String(date.getMonth() + 1).padStart(2, '0')
    const day = String(date.getDate()).padStart(2, '0')
    return `${year}-${month}-${day}`
  }

  const start = formatDate(startTs)
  if (endTs === null) {
    return `${start} ~ 至今`
  }
  const end = formatDate(endTs)
  if (start === end) {
    return start
  }
  return `${start} ~ ${end}`
}
</script>

<template>
  <div class="space-y-6">
    <!-- 成员活跃度排行 -->
    <RankListPro :members="memberRankData" title="成员活跃度排行" />

    <!-- 龙王排名 -->
    <LoadingState v-if="isLoadingDragonKing" text="正在统计龙王数据..." />
    <RankListPro
      v-else-if="dragonKingRankData.length > 0"
      :members="dragonKingRankData"
      title="🐉 龙王排名"
      :description="`每天发言最多的人+1（共 ${dragonKingAnalysis?.totalDays ?? 0} 天）`"
      unit="天"
    />

    <!-- 自言自语榜 -->
    <div class="rounded-xl border border-gray-200 bg-white shadow-sm dark:border-gray-800 dark:bg-gray-900">
      <div class="border-b border-gray-200 px-5 py-4 dark:border-gray-800">
        <h3 class="font-semibold text-gray-900 dark:text-white">🎤 自言自语榜</h3>
        <p class="mt-1 text-sm text-gray-500 dark:text-gray-400">连续发言 ≥3 条（间隔 ≤5 分钟）统计</p>
      </div>

      <LoadingState v-if="isLoadingMonologue" text="正在统计自言自语数据..." />

      <template v-else-if="monologueAnalysis && monologueAnalysis.rank.length > 0">
        <!-- 最高纪录卡片 -->
        <div
          v-if="monologueAnalysis.maxComboRecord"
          class="mx-5 mt-4 rounded-lg bg-gradient-to-r from-amber-50 to-orange-50 p-4 dark:from-amber-900/20 dark:to-orange-900/20"
        >
          <div class="flex items-center gap-2">
            <span class="text-2xl">🏆</span>
            <span class="font-semibold text-gray-900 dark:text-white">历史最高连击纪录</span>
          </div>
          <div class="mt-2 flex items-baseline gap-2">
            <span class="text-lg font-bold text-amber-600 dark:text-amber-400">
              {{ monologueAnalysis.maxComboRecord.memberName }}
            </span>
            <span class="text-sm text-gray-500">在</span>
            <span class="text-sm font-medium text-gray-700 dark:text-gray-300">
              {{ formatDateTime(monologueAnalysis.maxComboRecord.startTs) }}
            </span>
            <span class="text-sm text-gray-500">达成了</span>
            <span class="text-2xl font-bold text-red-600 dark:text-red-400">
              {{ monologueAnalysis.maxComboRecord.comboLength }} 连击！
            </span>
          </div>
        </div>

        <!-- 排行榜 -->
        <div class="divide-y divide-gray-100 dark:divide-gray-800">
          <div
            v-for="(member, index) in monologueAnalysis.rank.slice(0, 10)"
            :key="member.memberId"
            class="flex items-center gap-4 px-5 py-4 transition-colors hover:bg-gray-50 dark:hover:bg-gray-800/50"
          >
            <!-- 排名 -->
            <div
              class="flex h-8 w-8 shrink-0 items-center justify-center rounded-full text-sm font-bold"
              :class="
                index === 0
                  ? 'bg-gradient-to-r from-amber-400 to-orange-500 text-white'
                  : index === 1
                    ? 'bg-gradient-to-r from-gray-300 to-gray-400 text-white'
                    : index === 2
                      ? 'bg-gradient-to-r from-amber-600 to-amber-700 text-white'
                      : 'bg-gray-100 text-gray-600 dark:bg-gray-800 dark:text-gray-400'
              "
            >
              {{ index + 1 }}
            </div>

            <!-- 名字 + 标签 -->
            <div class="w-32 shrink-0">
              <p class="truncate font-medium text-gray-900 dark:text-white">
                {{ member.name }}
              </p>
              <p class="text-xs" :class="getComboLabel(member.maxCombo).color">
                {{ getComboLabel(member.maxCombo).text }}
              </p>
            </div>

            <!-- 三色能量条（相对于第一名的百分比） -->
            <div class="flex flex-1 items-center">
              <div class="h-4 w-full rounded-full bg-gray-100 dark:bg-gray-800">
                <div
                  class="flex h-full overflow-hidden rounded-full"
                  :style="{ width: `${(member.totalStreaks / maxTotalStreaks) * 100}%` }"
                >
                  <!-- 绿色：3-4句 -->
                  <div
                    v-if="member.lowStreak > 0"
                    class="h-full bg-green-500"
                    :style="{
                      width: `${(member.lowStreak / member.totalStreaks) * 100}%`,
                    }"
                    :title="`3-4句: ${member.lowStreak}次`"
                  />
                  <!-- 黄色：5-9句 -->
                  <div
                    v-if="member.midStreak > 0"
                    class="h-full bg-yellow-500"
                    :style="{
                      width: `${(member.midStreak / member.totalStreaks) * 100}%`,
                    }"
                    :title="`5-9句: ${member.midStreak}次`"
                  />
                  <!-- 红色：10+句 -->
                  <div
                    v-if="member.highStreak > 0"
                    class="h-full bg-red-500"
                    :style="{
                      width: `${(member.highStreak / member.totalStreaks) * 100}%`,
                    }"
                    :title="`10+句: ${member.highStreak}次`"
                  />
                </div>
              </div>
            </div>

            <!-- 统计数据 -->
            <div class="shrink-0 text-right">
              <div class="text-lg font-bold text-gray-900 dark:text-white">{{ member.totalStreaks }} 次</div>
              <div class="flex items-center justify-end gap-1 text-xs text-gray-500">
                <span>Max</span>
                <span class="font-semibold text-pink-600 dark:text-pink-400">{{ member.maxCombo }}</span>
              </div>
            </div>
          </div>
        </div>

        <!-- 图例 -->
        <div class="flex items-center justify-center gap-6 border-t border-gray-100 px-5 py-3 dark:border-gray-800">
          <div class="flex items-center gap-1.5">
            <div class="h-3 w-3 rounded-full bg-green-500" />
            <span class="text-xs text-gray-500">3-4句</span>
          </div>
          <div class="flex items-center gap-1.5">
            <div class="h-3 w-3 rounded-full bg-yellow-500" />
            <span class="text-xs text-gray-500">5-9句</span>
          </div>
          <div class="flex items-center gap-1.5">
            <div class="h-3 w-3 rounded-full bg-red-500" />
            <span class="text-xs text-gray-500">10+句</span>
          </div>
        </div>
      </template>

      <div v-else class="px-5 py-8 text-center text-sm text-gray-400">暂无自言自语数据</div>
    </div>

    <!-- 昵称变更记录区域 -->
    <div class="rounded-xl border border-gray-200 bg-white shadow-sm dark:border-gray-800 dark:bg-gray-900">
      <div class="border-b border-gray-200 px-5 py-4 dark:border-gray-800">
        <h3 class="font-semibold text-gray-900 dark:text-white">昵称变更记录</h3>
        <p class="mt-1 text-sm text-gray-500 dark:text-gray-400">
          {{
            isLoadingHistory
              ? '加载中...'
              : membersWithNicknameChanges.length > 0
                ? `${membersWithNicknameChanges.length} 位成员曾修改过昵称`
                : '暂无成员修改昵称'
          }}
        </p>
      </div>

      <div
        v-if="!isLoadingHistory && membersWithNicknameChanges.length > 0"
        class="divide-y divide-gray-100 dark:divide-gray-800"
      >
        <div
          v-for="member in membersWithNicknameChanges"
          :key="member.memberId"
          class="flex items-start gap-4 px-5 py-4"
        >
          <!-- 成员名称 -->
          <div class="w-32 shrink-0 pt-0.5 font-medium text-gray-900 dark:text-white">
            {{ member.name }}
          </div>

          <!-- 昵称历史（横向展示） -->
          <div class="flex flex-1 flex-wrap items-center gap-2">
            <template v-for="(item, index) in member.history" :key="index">
              <!-- 昵称标签 -->
              <div class="flex items-center gap-1.5 rounded-lg bg-gray-50 px-3 py-1.5 dark:bg-gray-800">
                <span
                  class="text-sm"
                  :class="item.endTs === null ? 'font-semibold text-[#de335e]' : 'text-gray-700 dark:text-gray-300'"
                >
                  {{ item.name }}
                </span>
                <UBadge v-if="item.endTs === null" color="primary" variant="soft" size="xs">当前</UBadge>
                <span class="text-xs text-gray-400">({{ formatPeriod(item.startTs, item.endTs) }})</span>
              </div>

              <!-- 箭头分隔符 -->
              <span v-if="index < member.history.length - 1" class="text-gray-300 dark:text-gray-600">→</span>
            </template>
          </div>
        </div>
      </div>

      <div v-else-if="!isLoadingHistory" class="px-5 py-8 text-center text-sm text-gray-400">
        该群组所有成员均未修改过昵称
      </div>

      <LoadingState v-else text="正在加载昵称变更记录..." />
    </div>

    <!-- 复读分析模块 -->
    <div class="rounded-xl border border-gray-200 bg-white shadow-sm dark:border-gray-800 dark:bg-gray-900">
      <div class="flex items-center justify-between border-b border-gray-200 px-5 py-4 dark:border-gray-800">
        <div>
          <h3 class="font-semibold text-gray-900 dark:text-white">复读分析</h3>
          <p class="mt-1 text-sm text-gray-500 dark:text-gray-400">
            {{
              isLoadingRepeat
                ? '加载中...'
                : repeatAnalysis
                  ? `共检测到 ${repeatAnalysis.totalRepeatChains} 次复读，平均复读链长度 ${repeatAnalysis.avgChainLength} 人`
                  : '暂无复读数据'
            }}
          </p>
        </div>
        <!-- 排序切换按钮 -->
        <div v-if="repeatAnalysis && repeatAnalysis.totalRepeatChains > 0" class="flex gap-1">
          <UButton
            size="xs"
            :variant="repeatRankMode === 'rate' ? 'solid' : 'ghost'"
            :color="repeatRankMode === 'rate' ? 'primary' : 'gray'"
            @click="repeatRankMode = 'rate'"
          >
            按复读率
          </UButton>
          <UButton
            size="xs"
            :variant="repeatRankMode === 'count' ? 'solid' : 'ghost'"
            :color="repeatRankMode === 'count' ? 'primary' : 'gray'"
            @click="repeatRankMode = 'count'"
          >
            按次数
          </UButton>
        </div>
      </div>

      <LoadingState v-if="isLoadingRepeat" text="正在分析复读数据..." />

      <div v-else-if="repeatAnalysis && repeatAnalysis.totalRepeatChains > 0" class="space-y-6 p-5">
        <!-- 复读链长度分布 & 最火复读内容 -->
        <div class="grid grid-cols-1 gap-6 lg:grid-cols-2">
          <!-- 复读链长度分布 -->
          <div class="rounded-lg border border-gray-100 bg-gray-50/50 dark:border-gray-800 dark:bg-gray-800/50">
            <div class="border-b border-gray-100 px-4 py-3 dark:border-gray-800">
              <h4 class="text-sm font-medium text-gray-700 dark:text-gray-300">📊 复读链长度分布</h4>
              <p class="mt-0.5 text-xs text-gray-500 dark:text-gray-400">每次复读有多少人参与</p>
            </div>
            <div class="p-4">
              <BarChart v-if="chainLengthChartData.labels.length > 0" :data="chainLengthChartData" :height="200" />
              <div v-else class="py-6 text-center text-sm text-gray-400">暂无数据</div>
            </div>
          </div>

          <!-- 最长复读链 TOP 10 -->
          <div class="rounded-lg border border-gray-100 bg-gray-50/50 dark:border-gray-800 dark:bg-gray-800/50">
            <div class="border-b border-gray-100 px-4 py-3 dark:border-gray-800">
              <h4 class="text-sm font-medium text-gray-700 dark:text-gray-300">🏆 最长复读链 TOP 10</h4>
              <p class="mt-0.5 text-xs text-gray-500 dark:text-gray-400">单次复读参与人数最多的内容</p>
            </div>
            <div v-if="repeatAnalysis.hotContents.length > 0" class="divide-y divide-gray-100 dark:divide-gray-800">
              <div
                v-for="(item, index) in repeatAnalysis.hotContents"
                :key="index"
                class="flex items-center gap-3 px-4 py-3"
              >
                <span
                  class="flex h-6 w-6 shrink-0 items-center justify-center rounded-full text-xs font-bold"
                  :class="
                    index === 0
                      ? 'bg-amber-100 text-amber-600 dark:bg-amber-900/30 dark:text-amber-400'
                      : index === 1
                        ? 'bg-gray-200 text-gray-600 dark:bg-gray-700 dark:text-gray-400'
                        : index === 2
                          ? 'bg-orange-100 text-orange-600 dark:bg-orange-900/30 dark:text-orange-400'
                          : 'bg-gray-100 text-gray-500 dark:bg-gray-800 dark:text-gray-500'
                  "
                >
                  {{ index + 1 }}
                </span>
                <span class="shrink-0 text-lg font-bold text-[#de335e]">{{ item.maxChainLength }}人</span>
                <div class="flex flex-1 items-center gap-1 overflow-hidden text-sm">
                  <span class="shrink-0 font-medium text-gray-900 dark:text-white">{{ item.originatorName }}：</span>
                  <span class="truncate text-gray-600 dark:text-gray-400" :title="item.content">
                    {{ truncateContent(item.content) }}
                  </span>
                </div>
                <div class="flex shrink-0 items-center gap-2 text-xs text-gray-500">
                  <span>{{ item.count }} 次</span>
                  <span class="text-gray-300 dark:text-gray-600">|</span>
                  <span>{{ formatDate(item.lastTs) }}</span>
                </div>
              </div>
            </div>
            <div v-else class="px-4 py-6 text-center text-sm text-gray-400">暂无数据</div>
          </div>
        </div>

        <!-- 最容易产生复读（原创者） -->
        <RankListPro
          v-if="originatorRankData.length > 0"
          :members="originatorRankData"
          title="🎯 谁的聊天最容易产生复读"
          :description="repeatRankMode === 'rate' ? '被复读次数 / 总发言数' : '发出的消息被别人复读的次数'"
          unit="次"
        />

        <!-- 最喜欢挑起复读（挑起者） -->
        <RankListPro
          v-if="initiatorRankData.length > 0"
          :members="initiatorRankData"
          title="🔥 谁最喜欢挑起复读"
          :description="repeatRankMode === 'rate' ? '挑起复读次数 / 总发言数' : '第二个发送相同消息、带起节奏的人'"
          unit="次"
        />

        <!-- 最喜欢打断复读（终结者） -->
        <RankListPro
          v-if="breakerRankData.length > 0"
          :members="breakerRankData"
          title="✂️ 谁喜欢打断复读"
          :description="repeatRankMode === 'rate' ? '打断复读次数 / 总发言数' : '终结复读链的人'"
          unit="次"
        />
      </div>

      <div v-else class="px-5 py-8 text-center text-sm text-gray-400">该群组暂无复读记录</div>
    </div>

    <!-- 口头禅分析模块 -->
    <LoadingState v-if="isLoadingCatchphrase" text="正在分析口头禅数据..." />

    <ListPro
      v-else-if="catchphraseAnalysis && catchphraseAnalysis.members.length > 0"
      :items="catchphraseAnalysis.members"
      title="💬 口头禅分析"
      :description="`分析了 ${catchphraseAnalysis.members.length} 位成员的高频发言`"
      countTemplate="共 {count} 位成员"
    >
      <template #item="{ item: member }">
        <div class="flex items-start gap-4">
          <!-- 成员名称 -->
          <div class="w-28 shrink-0 pt-1 font-medium text-gray-900 dark:text-white">
            {{ member.name }}
          </div>

          <!-- 口头禅列表 -->
          <div class="flex flex-1 flex-wrap items-center gap-2">
            <div
              v-for="(phrase, index) in member.catchphrases"
              :key="index"
              class="flex items-center gap-1.5 rounded-lg px-3 py-1.5"
              :class="
                index === 0
                  ? 'bg-amber-50 dark:bg-amber-900/20'
                  : index === 1
                    ? 'bg-gray-100 dark:bg-gray-800'
                    : 'bg-gray-50 dark:bg-gray-800/50'
              "
            >
              <span
                class="text-sm"
                :class="
                  index === 0 ? 'font-medium text-amber-700 dark:text-amber-400' : 'text-gray-700 dark:text-gray-300'
                "
                :title="phrase.content"
              >
                {{ truncateContent(phrase.content, 20) }}
              </span>
              <span class="text-xs text-gray-400">{{ phrase.count }}次</span>
            </div>
          </div>
        </div>
      </template>
    </ListPro>

    <div
      v-else
      class="rounded-xl border border-gray-200 bg-white px-5 py-8 text-center text-sm text-gray-400 shadow-sm dark:border-gray-800 dark:bg-gray-900"
    >
      暂无口头禅数据
    </div>
  </div>
</template>
