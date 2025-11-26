<script setup lang="ts">
const features = [
  {
    icon: '🏆',
    title: '活跃度分析',
    desc: '谁是群里的潜水王？',
    color: 'text-yellow-500',
    bg: 'bg-yellow-50',
    delay: '0ms',
  },
  {
    icon: '☁️',
    title: '词云生成',
    desc: '大家最爱说什么？',
    color: 'text-blue-500',
    bg: 'bg-blue-50',
    delay: '100ms',
  },
  {
    icon: '❤️',
    title: '情感分析',
    desc: '群聊氛围怎么样？',
    color: 'text-pink-500',
    bg: 'bg-pink-50',
    delay: '200ms',
  },
]

function handleImport() {
  console.log('Import clicked')
}

function openTutorial(type: 'ios' | 'android') {
  console.log('Tutorial:', type)
}
</script>

<template>
  <div class="relative flex h-full w-full overflow-hidden bg-white">
    <!-- Content Container -->
    <div class="relative z-10 flex h-full w-full flex-col items-center justify-center px-4">
      <!-- Hero Section -->
      <div class="mb-12 text-center">
        <div class="mb-6 inline-flex animate-bounce items-center justify-center rounded-3xl bg-white p-4 shadow-lg shadow-purple-100 ring-1 ring-gray-100">
          <UIcon name="i-heroicons-sparkles" class="h-8 w-8 text-purple-500" />
        </div>
        <h1 class="mb-4 bg-gradient-to-r from-purple-600 via-pink-500 to-orange-400 bg-clip-text text-5xl font-black tracking-tight text-transparent sm:text-6xl">
          探索你的群聊记忆
        </h1>
        <p class="text-lg font-medium text-gray-500">
          ChatLens 帮你发现那些被遗忘的有趣瞬间
        </p>
      </div>

      <!-- Feature Cards -->
      <div class="mb-12 grid max-w-4xl grid-cols-1 gap-6 sm:grid-cols-3">
        <div
          v-for="feature in features"
          :key="feature.title"
          class="group relative transform cursor-default rounded-2xl border border-gray-100 bg-white p-6 shadow-sm transition-all duration-300 hover:-translate-y-2 hover:shadow-xl hover:shadow-purple-500/10"
          :style="{ animationDelay: feature.delay }"
        >
          <div class="mb-4 text-4xl transition-transform duration-300 group-hover:scale-110">{{ feature.icon }}</div>
          <h3 class="mb-2 text-lg font-bold text-gray-900">{{ feature.title }}</h3>
          <p class="text-sm text-gray-500">{{ feature.desc }}</p>
        </div>
      </div>

      <!-- Actions -->
      <div class="flex flex-col items-center space-y-8">
        <button
          class="group relative inline-flex items-center justify-center rounded-full bg-gradient-to-r from-purple-500 to-pink-500 px-8 py-4 text-lg font-bold text-white shadow-lg shadow-purple-500/30 transition-all duration-300 hover:scale-105 hover:shadow-purple-500/50 focus:outline-none focus:ring-4 focus:ring-purple-500/30"
          @click="handleImport"
        >
          <UIcon name="i-heroicons-arrow-up-tray" class="mr-2 h-5 w-5 transition-transform group-hover:-translate-y-1" />
          立即导入聊天记录
        </button>

        <div class="flex items-center space-x-6 text-sm font-medium text-gray-400">
          <button class="flex items-center transition-colors hover:text-gray-600" @click="openTutorial('ios')">
            <UIcon name="i-simple-icons-apple" class="mr-1.5 h-4 w-4" />
            iOS 教程
          </button>
          <span class="h-1 w-1 rounded-full bg-gray-300"></span>
          <button class="flex items-center transition-colors hover:text-gray-600" @click="openTutorial('android')">
            <UIcon name="i-simple-icons-android" class="mr-1.5 h-4 w-4" />
            Android 教程
          </button>
        </div>
      </div>
    </div>
  </div>
</template>
