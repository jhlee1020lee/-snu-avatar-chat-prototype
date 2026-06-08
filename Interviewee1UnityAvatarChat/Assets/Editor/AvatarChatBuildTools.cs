using System;
using System.IO;
using UnityEditor;
using UnityEditor.Build.Reporting;
using UnityEditor.SceneManagement;
using UnityEngine;

public static class AvatarChatBuildTools
{
    private const string ScenePath = "Assets/Scenes/AvatarChat.unity";
    private const string BuildPath = "Build/Interviewee1UnityAvatarChat.exe";
    private const string WebGLBuildPath = "../Interviewee1CloneAI/public";

    [MenuItem("Avatar Chat/Create Scene")]
    public static void CreateScene()
    {
        Directory.CreateDirectory("Assets/Scenes");
        ApplyPlayerSettings();

        EditorSceneManager.NewScene(NewSceneSetup.EmptyScene, NewSceneMode.Single);
        GameObject app = new GameObject("Interviewee 1 Avatar Chat");
        app.AddComponent<AvatarChatApp>();

        EditorSceneManager.SaveScene(EditorSceneManager.GetActiveScene(), ScenePath);
        EditorBuildSettings.scenes = new[]
        {
            new EditorBuildSettingsScene(ScenePath, true)
        };

        AssetDatabase.SaveAssets();
        AssetDatabase.Refresh();
        Debug.Log($"Created avatar chat scene: {ScenePath}");
    }

    [MenuItem("Avatar Chat/Build Windows 1080p")]
    public static void BuildWindows()
    {
        CreateScene();
        Directory.CreateDirectory(Path.GetDirectoryName(BuildPath) ?? "Build");

        BuildPlayerOptions options = new BuildPlayerOptions
        {
            scenes = new[] { ScenePath },
            locationPathName = BuildPath,
            target = BuildTarget.StandaloneWindows64,
            options = BuildOptions.None
        };

        BuildReport report = BuildPipeline.BuildPlayer(options);
        if (report.summary.result != BuildResult.Succeeded)
        {
            throw new Exception($"Build failed: {report.summary.result}");
        }

        Debug.Log($"Built avatar chat app: {BuildPath}");
    }

    [MenuItem("Avatar Chat/Build WebGL")]
    public static void BuildWebGL()
    {
        CreateScene();
        if (Directory.Exists(WebGLBuildPath))
        {
            Directory.Delete(WebGLBuildPath, true);
        }
        Directory.CreateDirectory(WebGLBuildPath);

        PlayerSettings.WebGL.compressionFormat = WebGLCompressionFormat.Disabled;
        PlayerSettings.WebGL.decompressionFallback = false;
        PlayerSettings.WebGL.nameFilesAsHashes = false;

        BuildPlayerOptions options = new BuildPlayerOptions
        {
            scenes = new[] { ScenePath },
            locationPathName = WebGLBuildPath,
            target = BuildTarget.WebGL,
            options = BuildOptions.None
        };

        BuildReport report = BuildPipeline.BuildPlayer(options);
        if (report.summary.result != BuildResult.Succeeded)
        {
            throw new Exception($"WebGL build failed: {report.summary.result}");
        }

        Debug.Log($"Built avatar chat WebGL app: {WebGLBuildPath}");
    }

    private static void ApplyPlayerSettings()
    {
        PlayerSettings.companyName = "SNU Understanding Exceptional Children Group 3";
        PlayerSettings.productName = "겉!=속";
        PlayerSettings.fullScreenMode = FullScreenMode.Windowed;
        PlayerSettings.defaultScreenWidth = 1920;
        PlayerSettings.defaultScreenHeight = 1080;
        PlayerSettings.resizableWindow = false;
        PlayerSettings.runInBackground = true;
    }
}

