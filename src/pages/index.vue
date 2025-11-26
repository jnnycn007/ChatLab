<script setup lang="ts">
import { useChatStore } from '@/stores/chat'
import { storeToRefs } from 'pinia'
import Sidebar from '@/components/Sidebar.vue'
import WelcomeGuide from '@/components/WelcomeGuide.vue'

const chatStore = useChatStore()
const { currentSessionId } = storeToRefs(chatStore)
</script>

<template>
  <div class="flex h-screen w-full overflow-hidden bg-white dark:bg-gray-950">
    <!-- Sidebar -->
    <Sidebar />

    <!-- Main Content -->
    <main class="flex-1 overflow-hidden">
      <template v-if="!currentSessionId">
        <WelcomeGuide />
      </template>
      <template v-else>
        <!-- TODO: Analysis Dashboard -->
        <div class="flex h-full items-center justify-center text-gray-500">
          分析仪表盘 (开发中...)
        </div>
      </template>
    </main>
  </div>
</template>

